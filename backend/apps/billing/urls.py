"""
Billing URLs.
"""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.WorkflowItemListCreateView.as_view(), name="workflow-list"),
    path("<uuid:pk>/actions/", views.WorkflowActionView.as_view(), name="workflow-action"),
    path("categories/", views.BillCategoryListCreateView.as_view(), name="bill-category-list"),
    path("categories/<uuid:pk>/", views.BillCategoryDetailView.as_view(), name="bill-category-detail"),
    path("template/", views.BillTemplateView.as_view(), name="bill-template"),
]
