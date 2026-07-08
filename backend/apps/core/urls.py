"""
Health check URLs.
"""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.health_check, name="health"),
    path("ready/", views.health_ready, name="health-ready"),
    path("deep/", views.health_deep, name="health-deep"),
    path("metrics/", views.metrics, name="metrics"),
]
