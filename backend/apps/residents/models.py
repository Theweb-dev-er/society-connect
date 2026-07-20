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
    wing = models.CharField(max_length=50, blank=True, help_text="Wing or Block name")
    is_owner = models.BooleanField(default=True, help_text="True if owner, False if tenant")

    is_primary = models.BooleanField(default=True, help_text="True if head of family")
    relation_to_primary = models.CharField(max_length=50, blank=True, help_text="Spouse, Child, Parent, etc.")

    BHK_CHOICES = [
        ("1RK", "1RK"),
        ("1BHK", "1BHK"),
        ("2BHK", "2BHK"),
        ("3BHK", "3BHK"),
        ("4BHK", "4BHK"),
        ("5BHK", "5BHK"),
        ("6BHK", "6BHK"),
    ]
    bhk_type = models.CharField(
        max_length=10,
        choices=BHK_CHOICES,
        blank=True,
        default="",
        help_text="Flat type (1RK, 1BHK, 2BHK, etc.)"
    )

    class Meta:
        db_table = "residents"
        constraints = [
            models.UniqueConstraint(
                fields=["society", "wing", "flat_no"],
                condition=models.Q(is_primary=True),
                name="unique_primary_resident_per_flat"
            )
        ]

    def __str__(self):
        wing_prefix = f"{self.wing} - " if self.wing else ""
        return f"{self.user.name} - {wing_prefix}{self.flat_no}"


class Vehicle(BaseModel):
    """Vehicle registered to a resident profile."""

    TYPE_CHOICES = [
        ("2W", "Two Wheeler"),
        ("4W", "Four Wheeler"),
    ]
    
    resident = models.ForeignKey(
        ResidentProfile,
        on_delete=models.CASCADE,
        related_name="vehicles"
    )
    vehicle_type = models.CharField(max_length=2, choices=TYPE_CHOICES)
    vehicle_number = models.CharField(max_length=20, db_index=True)
    make_model = models.CharField(max_length=100, blank=True)

    class Meta:
        db_table = "vehicles"

    def __str__(self):
        return f"{self.vehicle_number} ({self.get_vehicle_type_display()})"
