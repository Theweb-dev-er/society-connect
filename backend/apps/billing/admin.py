from django.contrib import admin

from .models import WorkflowItem


@admin.register(WorkflowItem)
class WorkflowItemAdmin(admin.ModelAdmin):
    list_display = ["title", "type", "amount", "stage", "society", "submitted_by", "submitted_at"]
    list_filter = ["type", "stage", "society"]
    search_fields = ["title", "description"]
    readonly_fields = ["id", "created_at", "updated_at", "version"]
