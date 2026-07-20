"""
Society model.
"""

import uuid

from django.db import models


class Society(models.Model):
    """A housing society / residential complex."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    code = models.CharField(max_length=50, unique=True, db_index=True, help_text="Unique short code")
    address = models.TextField(blank=True)
    total_flats = models.PositiveIntegerField(default=0, help_text="Total number of flats/units")
    dual_role_policy = models.BooleanField(
        default=False,
        help_text="If True, a single person can hold both maker and checker roles",
    )
    account_balance = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    subscription_tier = models.CharField(
        max_length=20,
        choices=[
            ("free", "Free"),
            ("basic", "Basic"),
            ("premium", "Premium"),
            ("enterprise", "Enterprise"),
        ],
        default="free",
    )
    is_active = models.BooleanField(default=True)
    wings = models.JSONField(default=list, blank=True, help_text="List of wings/blocks in the society")
    bhk_types = models.JSONField(
        default=list,
        blank=True,
        help_text="Allowed flat BHK configurations for this society (e.g., ['1BHK', '2BHK', '3BHK'])",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name_plural = "societies"
        db_table = "societies"

    def __str__(self):
        return self.name
