"""
Billing URLs.
"""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.WorkflowItemListCreateView.as_view(), name="workflow-list"),
    path("<uuid:pk>/actions/", views.WorkflowActionView.as_view(), name="workflow-action"),
]
