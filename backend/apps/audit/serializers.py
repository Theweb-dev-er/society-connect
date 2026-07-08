"""
Audit log serializers.
"""

from rest_framework import serializers

from .models import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
    actor_name = serializers.SerializerMethodField()

    class Meta:
        model = AuditLog
        fields = [
            "id",
            "action",
            "actor",
            "actor_name",
            "actor_role",
            "target_item",
            "target_id",
            "comment",
            "timestamp",
            "ip_address",
        ]
        read_only_fields = fields

    def get_actor_name(self, obj):
        return obj.actor.name if obj.actor else "System"

