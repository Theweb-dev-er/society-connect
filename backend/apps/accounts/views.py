"""
Account views: OTP auth, JWT, current user.
"""

from django.conf import settings
from django.db import transaction
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import MeSerializer, OTPSendSerializer, OTPVerifySerializer
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
