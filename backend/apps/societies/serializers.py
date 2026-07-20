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
            "wings",
            "bhk_types",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

class OwnerRegistrationSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    phone = serializers.CharField(max_length=15)
    email = serializers.EmailField(allow_blank=True, required=False)

class SocietyRegistrationSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    address = serializers.CharField(allow_blank=True, required=False)
    total_flats = serializers.IntegerField(default=0)
    wings = serializers.JSONField(default=list)
    bhk_types = serializers.JSONField(default=list)
    owner = OwnerRegistrationSerializer()
