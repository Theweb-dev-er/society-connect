"""
Custom User model with phone as username.
"""

import uuid

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone

from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):
    """Custom user with phone as the unique identifier."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone = models.CharField(max_length=15, unique=True, db_index=True, help_text="Mobile number without country code")
    email = models.EmailField(blank=True)
    name = models.CharField(max_length=255, blank=True)

    # Society linkage
    society = models.ForeignKey(
        "societies.Society",
        on_delete=models.CASCADE,
        related_name="users",
        db_index=True,
        null=True,
        blank=True,
    )

    # Role within the app
    ROLE_CHOICES = [
        ("resident", "Resident"),
        ("security_guard", "Security Guard"),
        ("admin", "Admin"),
    ]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="resident")

    # Resident-specific role flags (only applicable when role=resident)
    is_admin = models.BooleanField(default=False, help_text="Society admin (can manage residents, guards)")
    is_maker = models.BooleanField(default=False, help_text="Can create expenses/bills")
    is_checker = models.BooleanField(default=False, help_text="Can review and forward items")
    is_approver = models.BooleanField(default=False, help_text="Can approve/reject final items")

    # Security guard-specific permissions (only applicable when role=security_guard)
    guard_can_add_entry = models.BooleanField(default=False)
    guard_can_manage_pre_approved = models.BooleanField(default=False)
    guard_can_view_inside_list = models.BooleanField(default=False)
    guard_can_view_gate_logs = models.BooleanField(default=False)

    # Django auth fields
    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)

    objects = UserManager()

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = ["name"]

    class Meta:
        ordering = ["-date_joined"]
        db_table = "users"
        indexes = [
            models.Index(fields=["society", "role", "is_active"]),
            models.Index(fields=["phone", "is_active"]),
        ]

    def __str__(self):
        return f"{self.name} ({self.phone})"

    def get_society_id(self):
        return str(self.society_id) if self.society_id else None

    def get_full_name(self):
        return self.name

    def get_short_name(self):
        return self.name.split()[0] if self.name else ""

    def clean(self):
        if self.is_admin and self.society_id:
            existing = User.objects.filter(
                society=self.society,
                is_admin=True,
            ).exclude(pk=self.pk).first()
            if existing:
                raise ValidationError(
                    f"An admin already exists for this society ({existing.name}). Only one admin is allowed per society."
                )
        super().clean()

    def save(self, *args, **kwargs):
        self.clean()
        super().save(*args, **kwargs)
