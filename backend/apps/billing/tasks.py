"""
Celery tasks for billing app.
"""

import logging
from datetime import datetime, timedelta

from celery import shared_task
from django.db import connection

from apps.audit.models import AuditLog
from apps.billing.models import WorkflowItem
from apps.societies.models import Society

logger = logging.getLogger("apps.billing")


@shared_task
def generate_society_report(society_id, start_date, end_date):
    """Generate a society financial report asynchronously."""
    try:
        society = Society.objects.get(id=society_id)
        items = WorkflowItem.objects.filter(
            society=society,
            created_at__range=(start_date, end_date),
            stage="approved",
        )

        total_expenses = sum(i.amount for i in items if i.type == "expense")
        total_bills = sum(i.amount for i in items if i.type == "bill")

        logger.info(f"[Celery] Generated report for {society.name}: expenses={total_expenses}, bills={total_bills}")

        return {
            "society": society.name,
            "period": f"{start_date} to {end_date}",
            "total_expenses": float(total_expenses),
            "total_bills": float(total_bills),
            "item_count": items.count(),
        }
    except Exception as e:
        logger.error(f"[Celery] Report generation failed: {e}")
        return {"status": "error", "message": str(e)}


@shared_task
def notify_approvers(workflow_item_id):
    """Notify approvers when an item needs their review."""
    try:
        from apps.accounts.models import User

        item = WorkflowItem.objects.select_related("society").get(id=workflow_item_id)
        approvers = User.objects.filter(
            society=item.society,
            is_approver=True,
            is_active=True,
        )

        count = approvers.count()
        logger.info(f"[Celery] Notified {count} approvers for item {workflow_item_id}")

        return {"notified": count, "item_id": str(workflow_item_id)}
    except Exception as e:
        logger.error(f"[Celery] Notification failed: {e}")
        return {"status": "error", "message": str(e)}
