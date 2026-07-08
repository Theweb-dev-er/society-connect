from django.contrib import admin

from .models import Society


@admin.register(Society)
class SocietyAdmin(admin.ModelAdmin):
    list_display = ["name", "code", "subscription_tier", "is_active", "created_at"]
    list_filter = ["subscription_tier", "is_active", "dual_role_policy"]
    search_fields = ["name", "code"]
    readonly_fields = ["id", "created_at", "updated_at"]
