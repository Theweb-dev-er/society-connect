"""
Resident URLs.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register(r'family-members', views.FamilyMemberViewSet, basename='family-member')
router.register(r'vehicles', views.VehicleViewSet, basename='vehicle')

urlpatterns = [
    path("", views.ResidentListView.as_view(), name="resident-list"),
    path("register/", views.ResidentProfileCreateView.as_view(), name="resident-register"),
    path("<uuid:pk>/roles/", views.ResidentRoleUpdateView.as_view(), name="resident-roles"),
    path("transfer/", views.ResidentAdminTransferView.as_view(), name="resident-admin-transfer"),
    path("admin-add/", views.AdminResidentAddView.as_view(), name="admin-resident-add"),
    path("admin-import/", views.AdminResidentImportCSVView.as_view(), name="admin-resident-import"),
    path("", include(router.urls)),
]
