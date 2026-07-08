from django.contrib import admin

from .models import GateLog, Visitor


@admin.register(Visitor)
class VisitorAdmin(admin.ModelAdmin):
    list_display = ["name", "type", "flat", "status", "expected_time", "society"]
    list_filter = ["type", "status", "society"]
    search_fields = ["name", "flat"]
    readonly_fields = ["id", "created_at", "updated_at"]


@admin.register(GateLog)
class GateLogAdmin(admin.ModelAdmin):
    list_display = ["visitor", "action", "guard", "timestamp", "society"]
    list_filter = ["action", "society"]
    search_fields = ["visitor__name", "notes"]
    readonly_fields = ["id", "timestamp", "created_at"]
    date_hierarchy = "timestamp"
