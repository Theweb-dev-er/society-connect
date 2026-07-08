from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = [
        "phone",
        "name",
        "role",
        "society",
        "is_admin",
        "is_maker",
        "is_checker",
        "is_approver",
        "is_active",
        "date_joined",
    ]
    list_filter = [
        "role",
        "is_admin",
        "is_maker",
        "is_checker",
        "is_approver",
        "is_active",
        "is_staff",
    ]
    search_fields = ["phone", "name", "email"]
    readonly_fields = ["id", "date_joined", "last_login"]

    fieldsets = (
        (None, {"fields": ("phone", "password")}),
        ("Personal info", {"fields": ("name", "email", "society")}),
        ("Roles", {"fields": ("role", "is_admin", "is_maker", "is_checker", "is_approver")}),
        (
            "Guard Permissions",
            {
                "fields": (
                    "guard_can_add_entry",
                    "guard_can_manage_pre_approved",
                    "guard_can_view_inside_list",
                    "guard_can_view_gate_logs",
                ),
                "classes": ("collapse",),
            },
        ),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("phone", "name", "password1", "password2", "society", "role"),
            },
        ),
    )
    ordering = ["-date_joined"]
