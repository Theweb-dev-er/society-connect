"""
Visitor serializers.
"""

from rest_framework import serializers

from .models import GateLog, Visitor


class VisitorSerializer(serializers.ModelSerializer):
    approved_by_name = serializers.CharField(source="approved_by.name", read_only=True)

    class Meta:
        model = Visitor
        fields = [
            "id",
            "name",
            "type",
            "flat",
            "expected_time",
            "status",
            "entry_time",
            "exit_time",
            "approved_by",
            "approved_by_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "entry_time", "exit_time", "created_at", "updated_at"]


class VisitorCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Visitor
        fields = ["name", "type", "flat", "expected_time"]


class GateLogSerializer(serializers.ModelSerializer):
    visitor_name = serializers.CharField(source="visitor.name", read_only=True)
    visitor_flat = serializers.CharField(source="visitor.flat", read_only=True)
    visitor_type = serializers.CharField(source="visitor.type", read_only=True)
    visitor_entry_time = serializers.DateTimeField(source="visitor.entry_time", read_only=True)
    visitor_exit_time = serializers.DateTimeField(source="visitor.exit_time", read_only=True)
    guard_name = serializers.CharField(source="guard.name", read_only=True)

    class Meta:
        model = GateLog
        fields = [
            "id",
            "visitor",
            "visitor_name",
            "visitor_flat",
            "visitor_type",
            "visitor_entry_time",
            "visitor_exit_time",
            "guard",
            "guard_name",
            "action",
            "timestamp",
            "notes",
            "created_at",
        ]
        read_only_fields = ["id", "timestamp", "created_at"]
