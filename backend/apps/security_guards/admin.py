from django.contrib import admin

from .models import SecurityGuard


@admin.register(SecurityGuard)
class SecurityGuardAdmin(admin.ModelAdmin):
    list_display = [
        "user",
        "gate",
        "shift",
        "is_active",
        "can_add_entry",
        "can_manage_pre_approved",
        "can_view_inside_list",
        "can_view_gate_logs",
        "society",
    ]
    list_filter = ["shift", "is_active", "society"]
    search_fields = ["user__name", "user__phone", "gate"]
    readonly_fields = ["id", "created_at", "updated_at"]
