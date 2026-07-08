"""
URL configuration for Society App backend.
"""

from django.conf import settings
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView

urlpatterns = [
    # Admin
    path("admin/", admin.site.urls),
    # API
    path("api/v1/auth/", include("apps.accounts.urls")),
    path("api/v1/societies/", include("apps.societies.urls")),
    path("api/v1/residents/", include("apps.residents.urls")),
    path("api/v1/guards/", include("apps.security_guards.urls")),
    path("api/v1/workflow-items/", include("apps.billing.urls")),
    path("api/v1/audit-logs/", include("apps.audit.urls")),
    path("api/v1/visitors/", include("apps.visitors.urls")),
    # Health checks
    path("health/", include("apps.core.urls")),
    # API Docs
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
]

if settings.DEBUG:
    from django.conf.urls.static import static

    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
