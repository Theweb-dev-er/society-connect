"""
Core middleware for request logging and multi-tenancy.
"""

import time
import uuid

from django.http import JsonResponse


class RequestLoggingMiddleware:
    """Log every request with structured JSON output."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.id = str(uuid.uuid4())
        request.start_time = time.time()

        response = self.get_response(request)

        duration_ms = int((time.time() - request.start_time) * 1000)
        user_id = getattr(request.user, "id", None)
        society_id = getattr(request.user, "society_id", None)

        log_entry = {
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "request_id": request.id,
            "method": request.method,
            "path": request.path,
            "status": response.status_code,
            "duration_ms": duration_ms,
            "user_id": str(user_id) if user_id else None,
            "society_id": str(society_id) if society_id else None,
            "ip": self._get_client_ip(request),
            "user_agent": request.META.get("HTTP_USER_AGENT", ""),
        }

        import logging

        logger = logging.getLogger("apps.core")
        logger.info(log_entry)

        return response

    def _get_client_ip(self, request):
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            return x_forwarded_for.split(",")[0].strip()
        return request.META.get("REMOTE_ADDR")


class TenantMiddleware:
    """
    Attach society_id from JWT token to request for tenant-scoped queries.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.society_id = None
        if hasattr(request, "user") and request.user.is_authenticated:
            request.society_id = getattr(request.user, "society_id", None)
        return self.get_response(request)
