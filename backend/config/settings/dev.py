"""
Development settings.
"""

from .base import *  # noqa

DEBUG = True

ALLOWED_HOSTS = ["*"]

CORS_ALLOW_ALL_ORIGINS = True

# Log everything in dev
LOGGING["loggers"]["django"]["level"] = "DEBUG"
LOGGING["loggers"]["apps"]["level"] = "DEBUG"

# Console email backend for dev
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# Redis cache for dev
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": REDIS_URL,
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        },
        "KEY_PREFIX": "society_app",
    }
}

# Disable throttling in dev
REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"] = {
    "anon": "10000/minute",
    "user": "10000/minute",
}

# Relaxed OTP rate limits for dev
OTP_RATE_LIMIT_PER_PHONE = 100
OTP_RATE_LIMIT_WINDOW_SECONDS = 60

# Debug toolbar
# INSTALLED_APPS += ["debug_toolbar"]
# MIDDLEWARE += ["debug_toolbar.middleware.DebugToolbarMiddleware"]
# INTERNAL_IPS = ["127.0.0.1"]
