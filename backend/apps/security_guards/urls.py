"""
Security Guard URLs.
"""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.SecurityGuardListCreateView.as_view(), name="guard-list"),
    path("<uuid:pk>/access/", views.SecurityGuardAccessView.as_view(), name="guard-access"),
    path("<uuid:pk>/toggle/", views.SecurityGuardToggleView.as_view(), name="guard-toggle"),
]
