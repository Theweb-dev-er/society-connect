from django.contrib import admin

from .models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ["action", "actor", "actor_role", "target_item", "society", "timestamp"]
    list_filter = ["action", "actor_role", "society"]
    search_fields = ["target_item", "comment", "actor__name"]
    readonly_fields = ["id", "timestamp"]
    date_hierarchy = "timestamp"
