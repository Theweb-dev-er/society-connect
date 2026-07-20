#!/usr/bin/env python3
"""
Seed script to populate the database with realistic test data.
Run with: python manage.py runscript seed_data
Or: DJANGO_SETTINGS_MODULE=config.settings.dev python scripts/seed_data.py
"""

import os
import random
import sys
import uuid

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.dev")
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import django

django.setup()

from django.db import transaction

from apps.accounts.models import User
from apps.audit.models import AuditLog
from apps.billing.models import WorkflowItem
from apps.residents.models import ResidentProfile
from apps.security_guards.models import SecurityGuard
from apps.societies.models import Society
from apps.visitors.models import GateLog, Visitor


FIRST_NAMES = ["Rohan", "Priya", "Rajesh", "Meera", "Vikram", "Lakshmi", "Ravi", "Anita", "Suresh", "Deepa"]
LAST_NAMES = ["Mehta", "Sharma", "Kumar", "Singh", "Patel", "Gupta", "Reddy", "Nair", "Iyer", "Joshi"]
FLAT_NOS = [f"Flat {i}" for i in range(200, 520)]
VISITOR_TYPES = ["guest", "delivery", "service"]


def create_society():
    """Create a test society."""
    society, _ = Society.objects.get_or_create(
        code="DEMO001",
        defaults={
            "name": "Sunshine Residency",
            "address": "123 Main Road, Bangalore",
            "dual_role_policy": True,
            "account_balance": 150000.00,
            "subscription_tier": "premium",
            "wings": ["Wing A", "Wing B", "Wing C"],
        },
    )
    return society


def create_residents(society, count=10):
    """Create resident users."""
    residents = []
    for i in range(count):
        phone = f"98{random.randint(10000000, 99999999)}"
        name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        user, created = User.objects.get_or_create(
            phone=phone,
            defaults={
                "name": name,
                "society": society,
                "role": "resident",
                "is_active": True,
            },
        )
        if created:
            flat_no = random.choice(FLAT_NOS)
            while ResidentProfile.objects.filter(society=society, flat_no=flat_no).exists():
                flat_no = random.choice(FLAT_NOS)
            profile, _ = ResidentProfile.objects.get_or_create(
                user=user,
                defaults={
                    "society": society,
                    "flat_no": flat_no,
                    "is_owner": random.choice([True, True, False]),
                },
            )
            residents.append(user)
    return residents


def create_explicit_residents(society):
    """Create the explicit test residents from TEST_CREDENTIALS.txt"""
    explicit_residents = [
        ("Amit Verma", "9111111111", "Flat 101"),
        ("Neha Gupta", "9222222222", "Flat 102"),
        ("Suresh Patel", "9333333333", "Flat 103"),
        ("Priya Nair", "9444444444", "Flat 104"),
        ("Vikram Rao", "9555555555", "Flat 105"),
        ("Ananya Desai", "9666666666", "Flat 106"),
        ("Rajesh Sharma", "9777777777", "Flat 107"),
        ("Kavita Menon", "9888888888", "Flat 108"),
        ("Deepak Joshi", "9900000001", "Flat 109"),
        ("Meera Iyer", "9900000002", "Flat 110"),
    ]
    residents = []
    for name, phone, flat in explicit_residents:
        user, created = User.objects.get_or_create(
            phone=phone,
            defaults={
                "name": name,
                "society": society,
                "role": "resident",
                "is_active": True,
            },
        )
        if not created:
            user.name = name
            user.role = "resident"
            user.society = society
            user.save()
        
        ResidentProfile.objects.update_or_create(
            user=user,
            defaults={
                "society": society,
                "flat_no": flat,
                "is_owner": True,
            },
        )
        residents.append(user)
    return residents


def create_admins(society):
    """Create single admin user per society (Case 1: admin only; Case 2: admin also holds a workflow role)."""
    admins = []
    user, created = User.objects.get_or_create(
        phone="9999999991",
        defaults={
            "name": "Secretary Raj",
            "society": society,
            "role": "resident",
            "is_admin": True,
            "is_maker": False,
            "is_checker": False,
            "is_approver": False,
        },
    )
    ResidentProfile.objects.get_or_create(
        user=user,
        defaults={
            "society": society,
            "flat_no": "Admin Office",
            "is_owner": True,
        },
    )
    admins.append(user)
    return admins


def create_workflow_users(society):
    """Create separate maker, checker, and approver users (Case 1)."""
    workflow_users = []
    configs = [
        ("Maker Mohan", "9999999992", "is_maker"),
        ("Checker Chandu", "9999999993", "is_checker"),
        ("Approver Anand", "9999999994", "is_approver"),
    ]
    for index, (name, phone, role_flag) in enumerate(configs):
        defaults = {
            "name": name,
            "society": society,
            "role": "resident",
            "is_admin": False,
            "is_maker": role_flag == "is_maker",
            "is_checker": role_flag == "is_checker",
            "is_approver": role_flag == "is_approver",
        }
        user, created = User.objects.get_or_create(phone=phone, defaults=defaults)
        if not created:
            # Reset to single role
            user.name = name
            user.society = society
            user.is_admin = False
            user.is_maker = role_flag == "is_maker"
            user.is_checker = role_flag == "is_checker"
            user.is_approver = role_flag == "is_approver"
            user.save()
        ResidentProfile.objects.update_or_create(
            user=user,
            defaults={"society": society, "flat_no": f"Flat {111 + index}", "is_owner": True},
        )
        workflow_users.append(user)
    return workflow_users


def create_security_guards(society):
    """Create security guard users."""
    guards = []
    for name, phone, gate in [
        ("Ram Singh", "8888888881", "Main Gate"),
        ("Sunil Yadav", "8888888882", "Side Gate"),
    ]:
        user, created = User.objects.get_or_create(
            phone=phone,
            defaults={
                "name": name,
                "society": society,
                "role": "security_guard",
                "is_active": True,
                "guard_can_add_entry": True,
                "guard_can_manage_pre_approved": True,
                "guard_can_view_inside_list": True,
                "guard_can_view_gate_logs": True,
            },
        )
        if not created:
            # Update existing guard user permissions
            user.guard_can_add_entry = True
            user.guard_can_manage_pre_approved = True
            user.guard_can_view_inside_list = True
            user.guard_can_view_gate_logs = True
            user.save()

        guard, _ = SecurityGuard.objects.get_or_create(
            user=user,
            defaults={
                "society": society,
                "gate": gate,
                "shift": random.choice(["day", "night"]),
                "is_active": True,
                "can_add_entry": True,
                "can_manage_pre_approved": True,
                "can_view_inside_list": True,
                "can_view_gate_logs": True,
            },
        )
        guards.append(user)
    return guards


def create_workflow_items(society, residents):
    """Create sample expenses and bills."""
    items = []
    stages = ["draft", "pending_checker", "pending_approver", "approved", "rejected"]
    types = ["expense", "bill"]
    titles = [
        "Electricity Bill - June",
        "Security Guard Salary",
        "Garden Maintenance",
        "Lift AMC",
        "Water Tank Cleaning",
        "Common Area Painting",
        "CCTV Maintenance",
        "Festival Decoration",
    ]

    for title in titles:
        item, created = WorkflowItem.objects.get_or_create(
            society=society,
            title=title,
            defaults={
                "type": random.choice(types),
                "amount": random.randint(1000, 50000),
                "description": f"Payment for {title}",
                "stage": random.choice(stages),
                "submitted_by": random.choice(residents),
                "payload": {"invoice_no": f"INV-{random.randint(1000,9999)}", "vendor": "ABC Services"},
            },
        )
        if created:
            items.append(item)
    return items


def create_visitors(society):
    """Create pre-approved visitors."""
    visitors = []
    visitor_data = [
        ("Rohan Mehta", "guest", "Flat 402", "expected"),
        ("Amazon Delivery", "delivery", "Flat 105", "expected"),
        ("Plumber - Rajesh", "service", "Flat 201", "expected"),
        ("Meera Sharma", "guest", "Flat 305", "expected"),
        ("Swiggy Delivery", "delivery", "Flat 502", "entered"),
        ("Priya Sharma", "guest", "Flat 102", "entered"),
    ]
    for name, vtype, flat, status in visitor_data:
        visitor, created = Visitor.objects.get_or_create(
            society=society,
            name=name,
            defaults={
                "type": vtype,
                "flat": flat,
                "status": status,
            },
        )
        if created:
            visitors.append(visitor)
    return visitors


def create_audit_logs(society, residents):
    """Create sample audit logs."""
    actions = ["Submitted", "Checked & Forwarded", "Approved", "Rejected"]
    targets = ["Expense #1234", "Bill #5678", "Maintenance Request #901"]
    logs = []
    for i in range(10):
        log, created = AuditLog.objects.get_or_create(
            society=society,
            action=random.choice(actions),
            target_item=random.choice(targets),
            defaults={
                "actor": random.choice(residents),
                "actor_role": random.choice(["Secretary", "Treasurer", "President"]),
                "comment": "Processed as per workflow" if random.random() > 0.5 else "",
            },
        )
        if created:
            logs.append(log)
    return logs


def main():
    print("Seeding database...")
    society = create_society()
    print(f"  Society: {society.name} ({society.code})")

    residents = create_residents(society, count=10)
    explicit_residents = create_explicit_residents(society)
    residents.extend(explicit_residents)
    print(f"  Residents: {len(residents)}")

    admins = create_admins(society)
    print(f"  Admins: {len(admins)}")

    workflow_users = create_workflow_users(society)
    print(f"  Workflow Users: {len(workflow_users)}")

    guards = create_security_guards(society)
    print(f"  Security Guards: {len(guards)}")

    items = create_workflow_items(society, residents)
    print(f"  Workflow Items: {len(items)}")

    visitors = create_visitors(society)
    print(f"  Visitors: {len(visitors)}")

    logs = create_audit_logs(society, residents)
    print(f"  Audit Logs: {len(logs)}")

    print("\nDone! Test credentials (Case 1 - separate admin + M/C/A):")
    print("  Superuser:  9999999999 / admin123")
    print("  Admin:      9999999991 (Secretary Raj)")
    print("  Maker:      9999999992 (Maker Mohan)")
    print("  Checker:    9999999993 (Checker Chandu)")
    print("  Approver:   9999999994 (Approver Anand)")
    print("  Guard 1:    8888888881")
    print("  Guard 2:    8888888882")
    print("  Residents:  any 98xxxxxxxx phone (OTP mock mode)")


if __name__ == "__main__":
    main()
