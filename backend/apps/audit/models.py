"""
Audit log model.
"""

import uuid

from django.db import models


class AuditLog(models.Model):
    """Records every significant action for compliance and debugging."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    society = models.ForeignKey(
        "societies.Society",
        on_delete=models.CASCADE,
        related_name="audit_logs",
        db_index=True,
    )
    action = models.CharField(max_length=100, db_index=True)
    actor = models.ForeignKey(
        "accounts.User",
        on_delete=models.SET_NULL,
        null=True,
        related_name="audit_actions",
    )
    actor_role = models.CharField(max_length=50, blank=True)
    target_item = models.CharField(max_length=255, db_index=True)
    target_id = models.UUIDField(null=True, blank=True)
    comment = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)

    class Meta:
        db_table = "audit_logs"
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["society", "timestamp"]),
            models.Index(fields=["society", "action", "timestamp"]),
        ]

    def __str__(self):
        return f"{self.action} by {self.actor} on {self.target_item}"
