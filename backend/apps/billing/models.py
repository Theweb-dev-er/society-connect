"""
Workflow item model for expenses and bills.
"""

import uuid

from django.db import models

from apps.core.models import BaseModel


class WorkflowItem(BaseModel):
    """An expense or bill moving through the approval workflow."""

    TYPE_CHOICES = [
        ("expense", "Expense"),
        ("bill", "Bill"),
    ]

    STAGE_CHOICES = [
        ("draft", "Draft"),
        ("pending_checker", "Pending Checker"),
        ("pending_approver", "Pending Approver"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
    ]

    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    title = models.CharField(max_length=255)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.TextField(blank=True)
    stage = models.CharField(max_length=20, choices=STAGE_CHOICES, default="draft")

    # Submitter
    submitted_by = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        related_name="submitted_workflows",
    )
    submitted_at = models.DateTimeField(null=True, blank=True)

    # Checker
    checked_by = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="checked_workflows",
    )
    checked_at = models.DateTimeField(null=True, blank=True)
    checker_comment = models.TextField(blank=True)

    # Approver
    approved_by = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="approved_workflows",
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    approver_comment = models.TextField(blank=True)

    # Rejection
    rejected_by = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="rejected_workflows",
    )
    rejected_at = models.DateTimeField(null=True, blank=True)
    rejection_reason = models.TextField(blank=True)

    # Flexible payload for additional data
    payload = models.JSONField(default=dict, blank=True)

    # Optimistic locking
    version = models.PositiveIntegerField(default=1)

    class Meta:
        db_table = "workflow_items"
        ordering = ["-submitted_at", "-created_at"]
        indexes = [
            models.Index(fields=["society", "stage", "type", "submitted_at"]),
            models.Index(fields=["society", "submitted_by", "stage"]),
        ]

    def __str__(self):
        return f"{self.title} ({self.stage})"


class BillCategory(models.Model):
    """Admin-managed billing categories for a society."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    society = models.ForeignKey(
        "societies.Society",
        on_delete=models.CASCADE,
        related_name="bill_categories",
        db_index=True,
    )
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "bill_categories"
        ordering = ["order", "created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["society", "name"],
                name="unique_bill_category_per_society",
            )
        ]

    def __str__(self):
        return f"{self.name} ({self.society.name})"


class BillTemplate(models.Model):
    """Stores the last used per-BHK rates for a society."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    society = models.OneToOneField(
        "societies.Society",
        on_delete=models.CASCADE,
        related_name="bill_template",
        db_index=True,
    )
    rates = models.JSONField(
        default=dict,
        help_text="Map of {category_id: {1RK: amount, 1BHK: amount, ...}}"
    )
    is_recurring = models.BooleanField(default=False, help_text="Auto-generate bills monthly via cron")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "bill_templates"

    def __str__(self):
        return f"BillTemplate for {self.society.name}"
