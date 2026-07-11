"""
Visitor URLs.
"""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.VisitorListCreateView.as_view(), name="visitor-list"),
    path("<uuid:pk>/", views.VisitorRetrieveView.as_view(), name="visitor-detail"),
    path("<uuid:pk>/enter/", views.VisitorEnterView.as_view(), name="visitor-enter"),
    path("<uuid:pk>/exit/", views.VisitorExitView.as_view(), name="visitor-exit"),
    path("inside/", views.InsideListView.as_view(), name="visitor-inside"),
    path("gate-logs/", views.GateLogListView.as_view(), name="gate-log-list"),
]
