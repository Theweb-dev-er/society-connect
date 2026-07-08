"""
Base models with multi-tenant support.
"""

import uuid

from django.db import models


class BaseModel(models.Model):
    """
    Abstract base model with UUID primary key, timestamps, and society_id.
    All society-scoped models should inherit from this.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    society = models.ForeignKey(
        "societies.Society",
        on_delete=models.CASCADE,
        related_name="%(class)s_set",
        db_index=True,
        help_text="The society this record belongs to",
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.__class__.__name__}({self.id})"
