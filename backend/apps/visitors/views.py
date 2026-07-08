"""
Visitor views.
"""

from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response

from apps.accounts.permissions import IsAdmin, IsSecurityGuard
from apps.core.pagination import CursorPagination

from .models import GateLog, Visitor
from .serializers import (
    GateLogSerializer,
    VisitorCreateSerializer,
    VisitorSerializer,
)


class VisitorListCreateView(generics.ListCreateAPIView):
    """List or create pre-approved visitors."""

    pagination_class = CursorPagination

    def get_serializer_class(self):
        if self.request.method == "POST":
            return VisitorCreateSerializer
        return VisitorSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [permissions.IsAuthenticated]
        return [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Visitor.objects.filter(society=self.request.user.society)

        # Filter by status
        status_filter = self.request.query_params.get("status")
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by type
        visitor_type = self.request.query_params.get("type")
        if visitor_type:
            queryset = queryset.filter(type=visitor_type)

        return queryset

    def perform_create(self, serializer):
        serializer.save(
            society=self.request.user.society,
            approved_by=self.request.user,
            status="expected",
        )


class VisitorEnterView(generics.GenericAPIView):
    """Mark a visitor as entered."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            visitor = Visitor.objects.get(pk=pk, society=request.user.society)
        except Visitor.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        if visitor.status != "expected":
            return Response(
                {"detail": f"Visitor is already {visitor.status}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        visitor.status = "entered"
        visitor.entry_time = timezone.now()
        visitor.save()

        # Log gate entry
        GateLog.objects.create(
            society=request.user.society,
            visitor=visitor,
            guard=request.user,
            action="entry",
        )

        return Response(VisitorSerializer(visitor).data, status=status.HTTP_200_OK)


class VisitorExitView(generics.GenericAPIView):
    """Mark a visitor as exited."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            visitor = Visitor.objects.get(pk=pk, society=request.user.society)
        except Visitor.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        if visitor.status != "entered":
            return Response(
                {"detail": f"Visitor must be entered first. Current status: {visitor.status}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        visitor.status = "exited"
        visitor.exit_time = timezone.now()
        visitor.save()

        # Log gate exit
        GateLog.objects.create(
            society=request.user.society,
            visitor=visitor,
            guard=request.user,
            action="exit",
        )

        return Response(VisitorSerializer(visitor).data, status=status.HTTP_200_OK)


class InsideListView(generics.ListAPIView):
    """List visitors currently inside the society."""

    serializer_class = VisitorSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None  # Usually small list

    def get_queryset(self):
        return Visitor.objects.filter(
            society=self.request.user.society,
            status="entered",
        )


class GateLogListView(generics.ListAPIView):
    """List gate entry/exit logs."""

    serializer_class = GateLogSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = CursorPagination

    def get_queryset(self):
        return GateLog.objects.filter(
            society=self.request.user.society
        ).select_related("visitor", "guard")
