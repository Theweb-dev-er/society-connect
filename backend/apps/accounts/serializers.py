"""
Account serializers.
"""

from rest_framework import serializers

from .models import DeviceToken, User


class UserSerializer(serializers.ModelSerializer):
    society_code = serializers.CharField(source="society.code", read_only=True)
    society_name = serializers.CharField(source="society.name", read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "phone",
            "email",
            "name",
            "society",
            "society_code",
            "society_name",
            "role",
            "is_admin",
            "is_maker",
            "is_checker",
            "is_approver",
            "guard_can_add_entry",
            "guard_can_manage_pre_approved",
            "guard_can_view_inside_list",
            "guard_can_view_gate_logs",
            "is_active",
            "date_joined",
        ]
        read_only_fields = ["id", "date_joined"]


class MeSerializer(serializers.ModelSerializer):
    """Current user profile with roles."""

    society_code = serializers.CharField(source="society.code", read_only=True)
    society_name = serializers.CharField(source="society.name", read_only=True)
    flat_no = serializers.SerializerMethodField()
    is_owner = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "phone",
            "name",
            "email",
            "role",
            "society_code",
            "society_name",
            "is_admin",
            "is_maker",
            "is_checker",
            "is_approver",
            "guard_can_add_entry",
            "guard_can_manage_pre_approved",
            "guard_can_view_inside_list",
            "guard_can_view_gate_logs",
            "flat_no",
            "is_owner",
        ]

    def get_flat_no(self, obj):
        try:
            return obj.resident_profile.flat_no
        except AttributeError:
            return None

    def get_is_owner(self, obj):
        try:
            return obj.resident_profile.is_owner
        except AttributeError:
            return False



class OTPSendSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=15, help_text="10-digit mobile number")


class OTPVerifySerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=15)
    code = serializers.CharField(max_length=10, help_text="OTP code received")


class DeviceTokenSerializer(serializers.ModelSerializer):
    token = serializers.CharField()

    class Meta:
        model = DeviceToken
        fields = ["id", "token", "device_type", "created_at", "updated_at"]
        read_only_fields = ["id", "created_at", "updated_at"]


