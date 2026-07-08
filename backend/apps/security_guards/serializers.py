"""
Security Guard serializers.
"""

from rest_framework import serializers

from .models import SecurityGuard


class SecurityGuardSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="user.name", read_only=True)
    phone = serializers.CharField(source="user.phone", read_only=True)

    class Meta:
        model = SecurityGuard
        fields = [
            "id",
            "user",
            "name",
            "phone",
            "gate",
            "shift",
            "is_active",
            "can_add_entry",
            "can_manage_pre_approved",
            "can_view_inside_list",
            "can_view_gate_logs",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class SecurityGuardAccessSerializer(serializers.Serializer):
    can_add_entry = serializers.BooleanField(required=False)
    can_manage_pre_approved = serializers.BooleanField(required=False)
    can_view_inside_list = serializers.BooleanField(required=False)
    can_view_gate_logs = serializers.BooleanField(required=False)


class SecurityGuardCreateSerializer(serializers.Serializer):
    """Create a guard with auto user creation."""

    name = serializers.CharField(max_length=100)
    phone = serializers.CharField(max_length=15)
    email = serializers.EmailField(required=False, allow_blank=True)
    gate = serializers.CharField(max_length=50, required=False, allow_blank=True)
    shift = serializers.ChoiceField(choices=[("day", "Day"), ("night", "Night"), ("rotating", "Rotating")], required=False)
    can_add_entry = serializers.BooleanField(required=False, default=True)
    can_manage_pre_approved = serializers.BooleanField(required=False, default=True)
    can_view_inside_list = serializers.BooleanField(required=False, default=True)
    can_view_gate_logs = serializers.BooleanField(required=False, default=True)
