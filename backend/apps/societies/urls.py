"""
Society URLs.
"""

from django.urls import path

from . import views

urlpatterns = [
    path("", views.SocietyListCreateView.as_view(), name="society-list"),
    path("register/", views.SocietyRegistrationView.as_view(), name="society-register"),
    path("check-phone/", views.CheckPhoneView.as_view(), name="check-phone"),
    path("by-code/", views.SocietyByCodeView.as_view(), name="society-by-code"),
    path("<uuid:pk>/", views.SocietyDetailView.as_view(), name="society-detail"),
]
