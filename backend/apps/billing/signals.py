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
