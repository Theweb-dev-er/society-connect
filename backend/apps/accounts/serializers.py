"""
Account serializers.
"""

from rest_framework import serializers

from .models import User


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
        ]


class OTPSendSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=15, help_text="10-digit mobile number")


class OTPVerifySerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=15)
    code = serializers.CharField(max_length=10, help_text="OTP code received")
