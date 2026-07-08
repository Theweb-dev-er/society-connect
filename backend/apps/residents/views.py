"""
Resident views.
"""

from django.db import transaction
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsAdmin
from apps.core.pagination import CursorPagination

from .models import ResidentProfile
from .serializers import (
    ResidentProfileSerializer,
    ResidentRoleUpdateSerializer,
    ResidentAdminTransferSerializer,
)


class ResidentListView(generics.ListAPIView):
    """List residents of the current user's society."""

    serializer_class = ResidentProfileSerializer
    permission_classes = [IsAdmin]
    pagination_class = CursorPagination

    def get_queryset(self):
        return ResidentProfile.objects.filter(
            society=self.request.user.society
        ).select_related("user")


class ResidentRoleUpdateView(generics.GenericAPIView):
    """Update role flags for a resident (admin only)."""

    permission_classes = [IsAdmin]
    serializer_class = ResidentRoleUpdateSerializer

    def patch(self, request, pk):
        try:
            profile = ResidentProfile.objects.select_related("user").get(
                pk=pk, society=request.user.society
            )
        except ResidentProfile.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        user = profile.user
        for field in ["is_admin", "is_maker", "is_checker", "is_approver"]:
            if field in serializer.validated_data:
                setattr(user, field, serializer.validated_data[field])
        user.save()

        return Response(
            {"detail": "Roles updated successfully.", "user_id": str(user.id)},
            status=status.HTTP_200_OK,
        )


class ResidentAdminTransferView(generics.GenericAPIView):
    """Transfer admin role from one resident to another atomically."""

    permission_classes = [IsAuthenticated]
    serializer_class = ResidentAdminTransferSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from_id = serializer.validated_data["from_resident_id"]
        to_id = serializer.validated_data["to_resident_id"]
        reason = serializer.validated_data.get("reason", "")

        society = request.user.society
        if not society:
            return Response({"detail": "No society associated."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from_profile = ResidentProfile.objects.select_related("user").get(pk=from_id, society=society)
            to_profile = ResidentProfile.objects.select_related("user").get(pk=to_id, society=society)
        except ResidentProfile.DoesNotExist:
            return Response({"detail": "Resident not found."}, status=status.HTTP_404_NOT_FOUND)

        from_user = from_profile.user
        to_user = to_profile.user

        # Only the current admin can transfer their own admin, or superuser
        if not (request.user.is_admin or request.user.is_superuser):
            return Response({"detail": "Only admin can transfer admin role."}, status=status.HTTP_403_FORBIDDEN)

        if not from_user.is_admin:
            return Response({"detail": "Source resident is not an admin."}, status=status.HTTP_400_BAD_REQUEST)

        if to_user.is_admin:
            return Response({"detail": "Target resident is already an admin."}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            from_user.is_admin = False
            from_user.save()

            to_user.is_admin = True
            to_user.save()

        return Response(
            {
                "detail": "Admin transferred successfully.",
                "from": str(from_user.id),
                "to": str(to_user.id),
                "reason": reason,
            },
            status=status.HTTP_200_OK,
        )
