"""
Audit log views.
"""

from rest_framework import generics, permissions

from apps.accounts.permissions import IsAdmin
from apps.core.pagination import CursorPagination

from .models import AuditLog
from .serializers import AuditLogSerializer


class AuditLogPagination(CursorPagination):
    ordering = "-timestamp"


class AuditLogListView(generics.ListAPIView):
    """List audit logs for the current society."""

    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = AuditLogPagination


    def get_queryset(self):
        queryset = AuditLog.objects.filter(society=self.request.user.society)

        # Filter by action
        action = self.request.query_params.get("action")
        if action:
            queryset = queryset.filter(action=action)

        # Filter by actor role
        role = self.request.query_params.get("role")
        if role:
            queryset = queryset.filter(actor_role=role)

        return queryset.select_related("actor")
