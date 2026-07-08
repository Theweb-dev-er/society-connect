"""
Maintenance Celery tasks.
"""

import logging
from datetime import datetime, timedelta

from celery import shared_task
from django.core.cache import cache
from django.db import connection

logger = logging.getLogger("apps.core")


@shared_task
def clear_expired_cache():
    """Clear expired cache entries."""
    # django-redis handles TTL automatically, but we can log cache stats
    logger.info("[Celery] Cache cleanup task executed")
    return {"status": "ok"}


@shared_task
def health_check_task():
    """Periodic health check task."""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        logger.info("[Celery] Health check passed: DB OK")
        return {"db": True, "timestamp": datetime.now().isoformat()}
    except Exception as e:
        logger.error(f"[Celery] Health check failed: {e}")
        return {"db": False, "error": str(e)}
