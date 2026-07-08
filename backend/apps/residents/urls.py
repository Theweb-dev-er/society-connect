"""
Resident URLs.
"""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.ResidentListView.as_view(), name="resident-list"),
    path("<uuid:pk>/roles/", views.ResidentRoleUpdateView.as_view(), name="resident-roles"),
    path("transfer/", views.ResidentAdminTransferView.as_view(), name="resident-admin-transfer"),
]
