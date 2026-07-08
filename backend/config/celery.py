"""
Celery config for Society App backend.
"""

import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.dev")

app = Celery("society_app")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
