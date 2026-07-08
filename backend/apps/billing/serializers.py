"""
Billing serializers.
"""

from rest_framework import serializers

from .models import WorkflowItem


class WorkflowItemSerializer(serializers.ModelSerializer):
    submitted_by_name = serializers.CharField(source="submitted_by.name", read_only=True)
    checked_by_name = serializers.CharField(source="checked_by.name", read_only=True)
    approved_by_name = serializers.CharField(source="approved_by.name", read_only=True)
    rejected_by_name = serializers.CharField(source="rejected_by.name", read_only=True)

    class Meta:
        model = WorkflowItem
        fields = [
            "id",
            "type",
            "title",
            "amount",
            "description",
            "stage",
            "submitted_by",
            "submitted_by_name",
            "submitted_at",
            "checked_by",
            "checked_by_name",
            "checked_at",
            "checker_comment",
            "approved_by",
            "approved_by_name",
            "approved_at",
            "approver_comment",
            "rejected_by",
            "rejected_by_name",
            "rejected_at",
            "rejection_reason",
            "payload",
            "version",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "version"]


class WorkflowItemCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkflowItem
        fields = ["type", "title", "amount", "description", "payload"]


class WorkflowActionSerializer(serializers.Serializer):
    action = serializers.ChoiceField(
        choices=["submit", "check", "approve", "reject"]
    )
    comment = serializers.CharField(required=False, allow_blank=True)
