"""
Django signals to auto-create audit logs on workflow transitions.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.audit.models import AuditLog

from .models import WorkflowItem


@receiver(post_save, sender=WorkflowItem)
def log_workflow_transition(sender, instance, created, **kwargs):
    """Create an audit log entry whenever a workflow item changes stage."""
    if created:
        AuditLog.objects.create(
            society=instance.society,
            action="Created",
            actor=instance.submitted_by,
            actor_role=_get_role(instance.submitted_by),
            target_item=f"{instance.type.title()}: {instance.title}",
            target_id=instance.id,
            comment=f"Amount: {instance.amount}",
        )
    else:
        # Determine what changed
        action_map = {
            "pending_checker": "Submitted",
            "pending_approver": "Checked & Forwarded",
            "approved": "Approved",
            "rejected": "Rejected",
        }
        action = action_map.get(instance.stage, "Updated")

        actor = None
        if instance.stage == "pending_checker":
            actor = instance.submitted_by
        elif instance.stage == "pending_approver":
            actor = instance.checked_by
        elif instance.stage == "approved":
            actor = instance.approved_by
        elif instance.stage == "rejected":
            actor = instance.rejected_by

        AuditLog.objects.create(
            society=instance.society,
            action=action,
            actor=actor,
            actor_role=_get_role(actor),
            target_item=f"{instance.type.title()}: {instance.title}",
            target_id=instance.id,
            comment=instance.approver_comment or instance.checker_comment or instance.rejection_reason or "",
        )

    # Trigger push notifications based on new stage
    recipients = []
    noti_title = ""
    noti_body = ""

    from apps.accounts.models import User

    if instance.stage == "pending_checker":
        recipients = list(
            User.objects.filter(
                society=instance.society,
                is_checker=True,
                is_active=True,
            ).values_list("id", flat=True)
        )
        noti_title = f"New {instance.type.title()} Pending Check"
        noti_body = f"'{instance.title}' (Amount: {instance.amount}) requires your review."
    elif instance.stage == "pending_approver":
        recipients = list(
            User.objects.filter(
                society=instance.society,
                is_approver=True,
                is_active=True,
            ).values_list("id", flat=True)
        )
        noti_title = f"{instance.type.title()} Pending Approval"
        noti_body = f"'{instance.title}' (Amount: {instance.amount}) has been checked and requires approval."
    elif instance.stage == "approved" and instance.submitted_by_id:
        recipients = [str(instance.submitted_by_id)]
        noti_title = f"{instance.type.title()} Approved"
        noti_body = f"Your '{instance.title}' has been approved."
    elif instance.stage == "rejected" and instance.submitted_by_id:
        recipients = [str(instance.submitted_by_id)]
        noti_title = f"{instance.type.title()} Rejected"
        noti_body = f"Your '{instance.title}' has been rejected. Reason: {instance.rejection_reason}"

    if recipients:
        from apps.core.tasks import send_push_notification_task

        send_push_notification_task.delay(
            user_ids=recipients,
            title=noti_title,
            body=noti_body,
            data={
                "type": "workflow_update",
                "item_id": str(instance.id),
                "stage": instance.stage,
                "item_type": instance.type,
            },
        )


def _get_role(user):
    if not user:
        return "Unknown"
    if user.is_admin:
        return "Admin"
    if user.is_checker and user.is_approver:
        return "Checker & Approver"
    if user.is_approver:
        return "Approver"
    if user.is_checker:
        return "Checker"
    if user.is_maker:
        return "Maker"
    return "Resident"
