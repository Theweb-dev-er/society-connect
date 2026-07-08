"""
Society URLs.
"""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.SocietyListCreateView.as_view(), name="society-list"),
    path("<uuid:pk>/", views.SocietyDetailView.as_view(), name="society-detail"),
]
