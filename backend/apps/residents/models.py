"""
Resident profile model.
"""

from django.db import models

from apps.core.models import BaseModel


class ResidentProfile(BaseModel):
    """Extended profile for a resident user."""

    user = models.OneToOneField(
        "accounts.User",
        on_delete=models.CASCADE,
        related_name="resident_profile",
    )
    flat_no = models.CharField(max_length=50, db_index=True)
    is_owner = models.BooleanField(default=True, help_text="True if owner, False if tenant")

    class Meta:
        db_table = "residents"
        unique_together = [["society", "flat_no"]]

    def __str__(self):
        return f"{self.user.name} - {self.flat_no}"
