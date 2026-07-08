"""
Resident serializers.
"""

from rest_framework import serializers

from .models import ResidentProfile


class ResidentProfileSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="user.name", read_only=True)
    phone = serializers.CharField(source="user.phone", read_only=True)
    is_admin = serializers.BooleanField(source="user.is_admin", read_only=True)
    is_maker = serializers.BooleanField(source="user.is_maker", read_only=True)
    is_checker = serializers.BooleanField(source="user.is_checker", read_only=True)
    is_approver = serializers.BooleanField(source="user.is_approver", read_only=True)

    class Meta:
        model = ResidentProfile
        fields = [
            "id",
            "user",
            "name",
            "phone",
            "flat_no",
            "is_owner",
            "is_admin",
            "is_maker",
            "is_checker",
            "is_approver",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class ResidentRoleUpdateSerializer(serializers.Serializer):
    is_admin = serializers.BooleanField(required=False)
    is_maker = serializers.BooleanField(required=False)
    is_checker = serializers.BooleanField(required=False)
    is_approver = serializers.BooleanField(required=False)


class ResidentAdminTransferSerializer(serializers.Serializer):
    from_resident_id = serializers.UUIDField()
    to_resident_id = serializers.UUIDField()
    reason = serializers.CharField(required=False, allow_blank=True)
