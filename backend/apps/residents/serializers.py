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
            "wing",
            "flat_no",
            "is_owner",
            "bhk_type",
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


class ResidentProfileCreateSerializer(serializers.ModelSerializer):
    society_code = serializers.CharField(write_only=True, required=False)
    society_id = serializers.UUIDField(write_only=True, required=False)
    name = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = ResidentProfile
        fields = ["society_code", "society_id", "wing", "flat_no", "is_owner", "name", "bhk_type"]

    def validate(self, attrs):
        if "society_code" not in attrs and "society_id" not in attrs:
            raise serializers.ValidationError("Either society_code or society_id is required.")
        return attrs


class FamilyMemberSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="user.name")
    phone = serializers.CharField(source="user.phone")

    class Meta:
        model = ResidentProfile
        fields = ["id", "name", "phone", "relation_to_primary", "is_primary", "bhk_type", "created_at"]
        read_only_fields = ["id", "is_primary", "created_at"]

    def create(self, validated_data):
        from apps.accounts.models import User
        from django.db import transaction

        user_data = validated_data.pop("user")
        name = user_data.get("name")
        phone = user_data.get("phone")
        
        request = self.context.get("request")
        primary_resident = request.user.resident_profile

        with transaction.atomic():
            user, created = User.objects.get_or_create(
                phone=phone,
                defaults={"name": name, "role": "resident", "society": primary_resident.society}
            )
            if not created and not user.society:
                user.society = primary_resident.society
                user.save()

            family_member, fm_created = ResidentProfile.objects.get_or_create(
                user=user,
                defaults={
                    "society": primary_resident.society,
                    "flat_no": primary_resident.flat_no,
                    "wing": primary_resident.wing,
                    "is_owner": primary_resident.is_owner,
                    "is_primary": False,
                    "relation_to_primary": validated_data.get("relation_to_primary", "")
                }
            )
        return family_member


from .models import Vehicle

class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ["id", "vehicle_type", "vehicle_number", "make_model", "created_at"]
        read_only_fields = ["id", "created_at"]

