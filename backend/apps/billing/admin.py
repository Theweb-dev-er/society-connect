from django.contrib import admin

from .models import WorkflowItem, BillCategory, BillTemplate


@admin.register(WorkflowItem)
class WorkflowItemAdmin(admin.ModelAdmin):
    list_display = ["title", "type", "amount", "stage", "society", "submitted_by", "submitted_at"]
    list_filter = ["type", "stage", "society"]
    search_fields = ["title", "description"]
    readonly_fields = ["id", "created_at", "updated_at", "version"]


@admin.register(BillCategory)
class BillCategoryAdmin(admin.ModelAdmin):
    list_display = ["name", "society", "is_active", "order", "created_at"]
    list_filter = ["is_active", "society"]
    search_fields = ["name", "description"]
    readonly_fields = ["id", "created_at"]


@admin.register(BillTemplate)
class BillTemplateAdmin(admin.ModelAdmin):
    list_display = ["society", "is_recurring", "updated_at"]
    list_filter = ["is_recurring", "society"]
    readonly_fields = ["id", "created_at", "updated_at"]
