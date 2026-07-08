"""
Security Guard views.
"""

from django.db import transaction
from rest_framework import generics, status
from rest_framework.response import Response

from apps.accounts.permissions import IsAdmin
from apps.core.pagination import CursorPagination

from .models import SecurityGuard
from .serializers import SecurityGuardAccessSerializer, SecurityGuardCreateSerializer, SecurityGuardSerializer


class SecurityGuardListCreateView(generics.ListCreateAPIView):
    """List or create security guards."""

    permission_classes = [IsAdmin]
    pagination_class = CursorPagination

    def get_serializer_class(self):
        if self.request.method == "POST":
            return SecurityGuardCreateSerializer
        return SecurityGuardSerializer

    def get_queryset(self):
        return SecurityGuard.objects.filter(
            society=self.request.user.society
        ).select_related("user")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        from apps.accounts.models import User

        with transaction.atomic():
            user, created = User.objects.get_or_create(
                phone=data["phone"],
                defaults={
                    "name": data["name"],
                    "email": data.get("email", ""),
                    "role": "security_guard",
                    "society": request.user.society,
                },
            )
            if not created:
                user.name = data["name"]
                user.role = "security_guard"
                user.society = request.user.society
                user.save()

            guard = SecurityGuard.objects.create(
                user=user,
                society=request.user.society,
                gate=data.get("gate", ""),
                shift=data.get("shift", "day"),
                is_active=True,
                can_add_entry=data.get("can_add_entry", True),
                can_manage_pre_approved=data.get("can_manage_pre_approved", True),
                can_view_inside_list=data.get("can_view_inside_list", True),
                can_view_gate_logs=data.get("can_view_gate_logs", True),
            )

        return Response(
            SecurityGuardSerializer(guard).data,
            status=status.HTTP_201_CREATED,
        )


class SecurityGuardAccessView(generics.GenericAPIView):
    """Update guard access permissions."""

    permission_classes = [IsAdmin]
    serializer_class = SecurityGuardAccessSerializer

    def patch(self, request, pk):
        try:
            guard = SecurityGuard.objects.get(pk=pk, society=request.user.society)
        except SecurityGuard.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        for field in [
            "can_add_entry",
            "can_manage_pre_approved",
            "can_view_inside_list",
            "can_view_gate_logs",
        ]:
            if field in serializer.validated_data:
                setattr(guard, field, serializer.validated_data[field])
        guard.save()

        return Response(
            SecurityGuardSerializer(guard).data,
            status=status.HTTP_200_OK,
        )


class SecurityGuardToggleView(generics.GenericAPIView):
    """Activate or deactivate a guard."""

    permission_classes = [IsAdmin]

    def post(self, request, pk):
        try:
            guard = SecurityGuard.objects.get(pk=pk, society=request.user.society)
        except SecurityGuard.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        guard.is_active = not guard.is_active
        guard.save()

        # Also toggle user account
        guard.user.is_active = guard.is_active
        guard.user.save()

        return Response(
            {
                "detail": f"Guard {'activated' if guard.is_active else 'deactivated'}.",
                "is_active": guard.is_active,
            },
            status=status.HTTP_200_OK,
        )
