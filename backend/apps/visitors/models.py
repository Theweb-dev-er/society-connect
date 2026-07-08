"""
Visitor and Gate Log models.
"""

from django.db import models

from apps.core.models import BaseModel


class Visitor(BaseModel):
    """A pre-approved or ad-hoc visitor."""

    TYPE_CHOICES = [
        ("guest", "Guest"),
        ("delivery", "Delivery"),
        ("service", "Service"),
    ]

    STATUS_CHOICES = [
        ("expected", "Expected"),
        ("entered", "Entered"),
        ("exited", "Exited"),
    ]

    name = models.CharField(max_length=255)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default="guest")
    flat = models.CharField(max_length=50, help_text="Flat number being visited")
    expected_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="expected")
    entry_time = models.DateTimeField(null=True, blank=True)
    exit_time = models.DateTimeField(null=True, blank=True)
    approved_by = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="approved_visitors",
    )

    class Meta:
        db_table = "visitors"
        ordering = ["-expected_time", "-created_at"]
        indexes = [
            models.Index(fields=["society", "status", "expected_time"]),
            models.Index(fields=["society", "type", "status"]),
        ]

    def __str__(self):
        return f"{self.name} ({self.type}) - {self.flat}"


class GateLog(BaseModel):
    """Record of every entry and exit through the gate."""

    visitor = models.ForeignKey(
        Visitor,
        on_delete=models.CASCADE,
        related_name="gate_logs",
    )
    guard = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        related_name="gate_logs",
    )
    action = models.CharField(
        max_length=10,
        choices=[("entry", "Entry"), ("exit", "Exit")],
    )
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    notes = models.TextField(blank=True)

    class Meta:
        db_table = "gate_logs"
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["society", "timestamp"]),
            models.Index(fields=["society", "visitor", "timestamp"]),
        ]

    def __str__(self):
        return f"{self.action.title()} - {self.visitor.name} at {self.timestamp}"
