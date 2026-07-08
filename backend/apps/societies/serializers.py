"""
Society serializers.
"""

from rest_framework import serializers

from .models import Society


class SocietySerializer(serializers.ModelSerializer):
    class Meta:
        model = Society
        fields = [
            "id",
            "name",
            "code",
            "address",
            "dual_role_policy",
            "account_balance",
            "subscription_tier",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]
