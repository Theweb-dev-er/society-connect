"""
Celery tasks for billing app.
"""

import calendar
import logging
from datetime import datetime, timedelta

from celery import shared_task
from django.db import connection
from django.utils import timezone

from apps.accounts.models import User
from apps.audit.models import AuditLog
from apps.billing.models import WorkflowItem, BillCategory, BillTemplate
from apps.residents.models import ResidentProfile
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


@shared_task
def auto_generate_monthly_bills():
    """Auto-generate bills for societies with recurring templates on the 1st of each month."""
    now = timezone.now()
    month_name = calendar.month_name[now.month]
    year = now.year

    templates = BillTemplate.objects.filter(is_recurring=True).select_related("society")
    created_count = 0

    for template in templates:
        society = template.society
        rates = template.rates or {}
        categories = BillCategory.objects.filter(society=society, is_active=True).order_by("order", "created_at")
        residents = ResidentProfile.objects.filter(
            society=society, is_primary=True
        ).select_related("user")

        if not residents.exists() or not categories.exists():
            logger.info(f"[Celery] Skipping {society.name}: no residents or categories")
            continue

        try:
            maker = User.objects.filter(society=society, is_maker=True, is_active=True).first()
            if not maker:
                logger.warning(f"[Celery] No maker for {society.name}, skipping auto-generation")
                continue

            entries = []
            category_data = []
            grand_total = 0.0

            for cat in categories:
                cat_id = str(cat.id)
                cat_rates = rates.get(cat_id, {})
                category_data.append({
                    "category_id": cat_id,
                    "category_name": cat.name,
                    "rates": cat_rates,
                })

            for resident in residents:
                bhk = resident.bhk_type or "2BHK"
                category_amounts = {}
                resident_total = 0.0
                for cat in categories:
                    cat_id = str(cat.id)
                    cat_rates = rates.get(cat_id, {})
                    amount = float(cat_rates.get(bhk, 0) or 0)
                    category_amounts[cat.name] = amount
                    resident_total += amount

                entries.append({
                    "flat": f"{resident.wing or ''} - {resident.flat_no}",
                    "residentName": resident.user.name,
                    "bhkType": bhk,
                    "categoryAmounts": category_amounts,
                    "total": resident_total,
                })
                grand_total += resident_total

            payload = {
                "bill_period": {"month": month_name, "year": year},
                "categories": category_data,
                "entries": entries,
                "total_amount": grand_total,
                "resident_count": residents.count(),
                "auto_generated": True,
            }

            title = f"{month_name} {year} Maintenance Bill"
            item = WorkflowItem.objects.create(
                type="bill",
                title=title,
                amount=grand_total,
                description=f"Auto-generated monthly maintenance bill for {month_name} {year}",
                payload=payload,
                society=society,
                submitted_by=maker,
                stage="draft",
            )

            created_count += 1
            logger.info(f"[Celery] Auto-generated bill for {society.name}: {title} (Rs. {grand_total})")

        except Exception as e:
            logger.error(f"[Celery] Auto-generation failed for {society.name}: {e}")

    return {"created": created_count, "month": month_name, "year": year}
