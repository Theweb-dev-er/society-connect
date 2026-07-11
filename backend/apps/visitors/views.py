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
        return [permissions.IsAuthenticated()]


    def get_queryset(self):
        user = self.request.user
        queryset = Visitor.objects.filter(society=user.society)

        # If resident, restrict to their own flat
        if user.role == "resident":
            try:
                queryset = queryset.filter(flat=user.resident_profile.flat_no)
            except AttributeError:
                return Visitor.objects.none()

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
        user = self.request.user
        if user.role == "security_guard":
            visitor = serializer.save(
                society=user.society,
                approved_by=None,
                status="expected",
            )
            # Trigger push notification to resident(s)
            from apps.residents.models import ResidentProfile
            recipient_ids = [
                str(uid)
                for uid in ResidentProfile.objects.filter(
                    society=visitor.society,
                    flat_no=visitor.flat,
                ).values_list("user_id", flat=True)
            ]

            if recipient_ids:
                from apps.core.tasks import send_push_notification_task
                send_push_notification_task.delay(
                    user_ids=recipient_ids,
                    title="Visitor Approval Request",
                    body=f"{visitor.name} ({visitor.type.title()}) is waiting at the main gate for Flat {visitor.flat}.",
                    data={
                        "type": "visitor_approval_request",
                        "visitor_id": str(visitor.id),
                        "visitor_name": visitor.name,
                        "flat": visitor.flat,
                    },
                )
        else:
            serializer.save(
                society=user.society,
                approved_by=user,
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
        if not visitor.approved_by:
            # If the user performing entry is a resident, set them as the approver
            if request.user.role == "resident":
                visitor.approved_by = request.user
        visitor.save()

        # Log gate entry
        GateLog.objects.create(
            society=request.user.society,
            visitor=visitor,
            guard=request.user if request.user.role == "security_guard" else None,
            action="entry",
        )


        # Trigger push notification to resident(s)
        recipient_ids = []
        if visitor.approved_by_id:
            recipient_ids = [str(visitor.approved_by_id)]
        else:
            # Query all residents in the flat
            from apps.residents.models import ResidentProfile

            recipient_ids = [
                str(uid)
                for uid in ResidentProfile.objects.filter(
                    society=visitor.society,
                    flat_no=visitor.flat,
                ).values_list("user_id", flat=True)
            ]


        if recipient_ids:
            from apps.core.tasks import send_push_notification_task
            send_push_notification_task.delay(
                user_ids=recipient_ids,
                title="Visitor Arrived",
                body=f"Your visitor {visitor.name} has entered the gate.",
                data={
                    "type": "visitor_entry",
                    "visitor_id": str(visitor.id),
                    "visitor_name": visitor.name,
                    "flat": visitor.flat,
                },
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


class VisitorRetrieveView(generics.RetrieveAPIView):
    """Retrieve visitor details by ID."""

    serializer_class = VisitorSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Visitor.objects.filter(society=self.request.user.society)

