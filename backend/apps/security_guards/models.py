"""
Security Guard model.
"""

from django.db import models

from apps.core.models import BaseModel


class SecurityGuard(BaseModel):
    """Security guard profile with access permissions."""

    user = models.OneToOneField(
        "accounts.User",
        on_delete=models.CASCADE,
        related_name="guard_profile",
    )
    gate = models.CharField(max_length=50, blank=True, help_text="Assigned gate")
    shift = models.CharField(
        max_length=20,
        choices=[
            ("day", "Day"),
            ("night", "Night"),
            ("rotating", "Rotating"),
        ],
        default="day",
    )
    is_active = models.BooleanField(default=True)

    # Access permissions
    can_add_entry = models.BooleanField(default=False)
    can_manage_pre_approved = models.BooleanField(default=False)
    can_view_inside_list = models.BooleanField(default=False)
    can_view_gate_logs = models.BooleanField(default=False)

    class Meta:
        db_table = "security_guards"

    def save(self, *args, **kwargs):
        if self.user:
            self.user.guard_can_add_entry = self.can_add_entry
            self.user.guard_can_manage_pre_approved = self.can_manage_pre_approved
            self.user.guard_can_view_inside_list = self.can_view_inside_list
            self.user.guard_can_view_gate_logs = self.can_view_gate_logs
            self.user.save(update_fields=[
                "guard_can_add_entry",
                "guard_can_manage_pre_approved",
                "guard_can_view_inside_list",
                "guard_can_view_gate_logs",
            ])
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.name} - Gate {self.gate}"

