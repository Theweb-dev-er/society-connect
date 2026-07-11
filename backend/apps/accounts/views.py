"""
Account views: OTP auth, JWT, current user.
"""

from django.conf import settings
from django.db import transaction
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import DeviceToken, User
from .serializers import DeviceTokenSerializer, MeSerializer, OTPSendSerializer, OTPVerifySerializer
from .tasks import send_otp_async
from .utils import generate_otp, send_otp_sms, verify_otp


class OTPSendView(APIView):
    """Send OTP to a phone number."""

    permission_classes = [permissions.AllowAny]
    throttle_scope = "otp_send"

    def post(self, request):
        serializer = OTPSendSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data["phone"].strip()

        try:
            code = generate_otp(phone)
        except ValueError as e:
            return Response(
                {"detail": str(e)},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        # Send OTP asynchronously via Celery in production
        if settings.OTP_PROVIDER == "mock":
            send_otp_sms(phone, code)  # Synchronous for dev
        else:
            send_otp_async.delay(phone, code)

        return Response(
            {
                "message": "OTP sent successfully",
                "expires_in": settings.OTP_EXPIRY_SECONDS,
            },
            status=status.HTTP_200_OK,
        )


class OTPVerifyView(APIView):
    """Verify OTP and return JWT tokens."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = OTPVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data["phone"].strip()
        code = serializer.validated_data["code"].strip()

        if not verify_otp(phone, code):
            return Response(
                {"detail": "Invalid or expired OTP."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get or create user
        user, created = User.objects.get_or_create(
            phone=phone,
            defaults={"name": "User", "role": "resident"},
        )

        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": MeSerializer(user).data,
                "is_new_user": created,
            },
            status=status.HTTP_200_OK,
        )


class MeView(generics.RetrieveAPIView):
    """Current authenticated user profile."""

    serializer_class = MeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class TokenRefreshView(APIView):
    """Refresh access token using refresh token."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from rest_framework_simplejwt.views import TokenRefreshView as JWTRFView

        return JWTRFView.as_view()(request._request)


class DeviceTokenView(APIView):
    """Register or delete FCM device registration tokens."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = serializer.validated_data["token"].strip()
        device_type = serializer.validated_data.get("device_type", "android")

        # Upsert: If token already exists, associate it with the current user
        # (in case a device was handed to another user).
        device_token, created = DeviceToken.objects.update_or_create(
            token=token,
            defaults={"user": request.user, "device_type": device_type},
        )

        return Response(
            DeviceTokenSerializer(device_token).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    def delete(self, request):
        token = request.data.get("token")
        if not token:
            return Response({"detail": "Token is required."}, status=status.HTTP_400_BAD_REQUEST)

        DeviceToken.objects.filter(user=request.user, token=token).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

