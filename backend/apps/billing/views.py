"""
Billing / Workflow views.
"""

from django.db import transaction
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response

from apps.accounts.permissions import IsAdmin, IsApprover, IsChecker, IsMaker
from apps.core.pagination import CursorPagination

from .models import WorkflowItem, BillCategory, BillTemplate
from .serializers import (
    WorkflowActionSerializer,
    WorkflowItemCreateSerializer,
    WorkflowItemSerializer,
    BillCategorySerializer,
    BillTemplateSerializer,
)


class WorkflowItemListCreateView(generics.ListCreateAPIView):
    """List workflow items or create a new one."""

    pagination_class = CursorPagination

    def get_serializer_class(self):
        if self.request.method == "POST":
            return WorkflowItemCreateSerializer
        return WorkflowItemSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsMaker()]
        # All authenticated users can view items relevant to them
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        queryset = WorkflowItem.objects.filter(society=user.society)

        # Role-based filtering
        stage = self.request.query_params.get("stage")
        if stage:
            queryset = queryset.filter(stage=stage)

        item_type = self.request.query_params.get("type")
        if item_type:
            queryset = queryset.filter(type=item_type)

        # If checker, show items pending checker review
        if user.is_checker and not user.is_admin:
            queryset = queryset.filter(stage="pending_checker")

        # If approver, show items pending approver review
        if user.is_approver and not user.is_admin:
            queryset = queryset.filter(stage="pending_approver")

        return queryset.select_related(
            "submitted_by", "checked_by", "approved_by", "rejected_by"
        )

    def perform_create(self, serializer):
        serializer.save(
            society=self.request.user.society,
            submitted_by=self.request.user,
            stage="draft",
        )


class WorkflowActionView(generics.GenericAPIView):
    """Perform workflow actions: submit, check, approve, reject."""

    serializer_class = WorkflowActionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            item = WorkflowItem.objects.select_for_update().get(
                pk=pk, society=request.user.society
            )
        except WorkflowItem.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        action = serializer.validated_data["action"]
        comment = serializer.validated_data.get("comment", "")
        user = request.user

        with transaction.atomic():
            # Reload with lock
            item = WorkflowItem.objects.select_for_update().get(pk=pk)

            if action == "submit":
                if item.stage != "draft":
                    return Response(
                        {"detail": "Can only submit draft items."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                item.stage = "pending_checker"
                item.submitted_at = timezone.now()

            elif action == "check":
                if not user.is_checker and not user.is_admin:
                    return Response(
                        {"detail": "Only checkers can perform this action."},
                        status=status.HTTP_403_FORBIDDEN,
                    )
                if item.stage != "pending_checker":
                    return Response(
                        {"detail": "Item is not pending checker review."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                item.stage = "pending_approver"
                item.checked_by = user
                item.checked_at = timezone.now()
                item.checker_comment = comment

            elif action == "approve":
                if not user.is_approver and not user.is_admin:
                    return Response(
                        {"detail": "Only approvers can perform this action."},
                        status=status.HTTP_403_FORBIDDEN,
                    )
                if item.stage != "pending_approver":
                    return Response(
                        {"detail": "Item is not pending approver review."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                item.stage = "approved"
                item.approved_by = user
                item.approved_at = timezone.now()
                item.approver_comment = comment

            elif action == "reject":
                if not (user.is_checker or user.is_approver or user.is_admin):
                    return Response(
                        {"detail": "Only checkers or approvers can reject."},
                        status=status.HTTP_403_FORBIDDEN,
                    )
                if item.stage not in ["pending_checker", "pending_approver"]:
                    return Response(
                        {"detail": "Can only reject pending items."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                item.stage = "rejected"
                item.rejected_by = user
                item.rejected_at = timezone.now()
                item.rejection_reason = comment

            item.version += 1
            item.save()

        return Response(
            WorkflowItemSerializer(item).data,
            status=status.HTTP_200_OK,
        )


class BillCategoryListCreateView(generics.ListCreateAPIView):
    """List or create billing categories for the current society."""

    serializer_class = BillCategorySerializer
    pagination_class = CursorPagination

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsMaker()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        return BillCategory.objects.filter(society=self.request.user.society)

    def perform_create(self, serializer):
        serializer.save(society=self.request.user.society)


class BillCategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a billing category."""

    serializer_class = BillCategorySerializer

    def get_permissions(self):
        if self.request.method in ("PUT", "PATCH", "DELETE"):
            return [IsMaker()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        return BillCategory.objects.filter(society=self.request.user.society)


class BillTemplateView(generics.RetrieveUpdateAPIView):
    """Retrieve or update the bill template for the current society."""

    serializer_class = BillTemplateSerializer
    permission_classes = [IsMaker]

    def get_object(self):
        template, created = BillTemplate.objects.get_or_create(
            society=self.request.user.society,
            defaults={"rates": {}, "is_recurring": False}
        )
        return template

    def perform_update(self, serializer):
        serializer.save(society=self.request.user.society)
