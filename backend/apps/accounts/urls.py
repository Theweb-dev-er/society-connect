"""
Account URLs.
"""

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

urlpatterns = [
    path("otp/send/", views.OTPSendView.as_view(), name="otp-send"),
    path("otp/verify/", views.OTPVerifyView.as_view(), name="otp-verify"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("me/", views.MeView.as_view(), name="me"),
    path("device-tokens/", views.DeviceTokenView.as_view(), name="device-tokens"),
]
