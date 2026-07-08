"""
Health check views.
"""

from django.db import connection
from django.http import JsonResponse

import redis
from django.conf import settings


def health_check(request):
    """Liveness probe."""
    return JsonResponse({"status": "ok"})


def health_ready(request):
    """Readiness probe — check DB and Redis."""
    checks = {"db": False, "redis": False, "celery": True}

    # DB check
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            checks["db"] = True
    except Exception:
        pass

    # Redis check
    try:
        r = redis.from_url(settings.REDIS_URL, socket_connect_timeout=2)
        r.ping()
        checks["redis"] = True
    except Exception:
        pass

    all_ok = all(checks.values())
    return JsonResponse(
        {"status": "ok" if all_ok else "not_ready", "checks": checks},
        status=200 if all_ok else 503,
    )


def health_deep(request):
    """Deep health check with latency."""
    import time

    results = {}

    # DB latency
    try:
        start = time.time()
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        results["db_latency_ms"] = int((time.time() - start) * 1000)
        results["db"] = True
    except Exception as e:
        results["db"] = False
        results["db_error"] = str(e)

    # Redis latency
    try:
        start = time.time()
        r = redis.from_url(settings.REDIS_URL, socket_connect_timeout=2)
        r.ping()
        results["redis_latency_ms"] = int((time.time() - start) * 1000)
        results["redis"] = True
    except Exception as e:
        results["redis"] = False
        results["redis_error"] = str(e)

    all_ok = results.get("db") and results.get("redis")
    return JsonResponse(
        {"status": "ok" if all_ok else "degraded", "results": results},
        status=200 if all_ok else 503,
    )


def metrics(request):
    """Simple metrics endpoint (alternative to Prometheus)."""
    import time
    from django.db import connection

    from apps.accounts.models import User
    from apps.societies.models import Society
    from apps.visitors.models import GateLog, Visitor
    from apps.billing.models import WorkflowItem

    stats = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "users_total": User.objects.count(),
        "users_active": User.objects.filter(is_active=True).count(),
        "societies_total": Society.objects.count(),
        "societies_active": Society.objects.filter(is_active=True).count(),
        "visitors_expected": Visitor.objects.filter(status="expected").count(),
        "visitors_inside": Visitor.objects.filter(status="entered").count(),
        "gate_logs_total": GateLog.objects.count(),
        "workflow_items_total": WorkflowItem.objects.count(),
        "workflow_items_approved": WorkflowItem.objects.filter(stage="approved").count(),
        "workflow_items_pending": WorkflowItem.objects.filter(stage__in=["pending_checker", "pending_approver"]).count(),
    }

    # DB connection pool info
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT count(*) FROM pg_stat_activity WHERE datname = current_database()")
            stats["db_connections"] = cursor.fetchone()[0]
    except Exception:
        stats["db_connections"] = -1

    return JsonResponse(stats)
