from django.contrib import admin

from .models import ResidentProfile


@admin.register(ResidentProfile)
class ResidentProfileAdmin(admin.ModelAdmin):
    list_display = ["user", "flat_no", "is_owner", "society", "created_at"]
    list_filter = ["is_owner", "society"]
    search_fields = ["user__name", "user__phone", "flat_no"]
    readonly_fields = ["id", "created_at", "updated_at"]
