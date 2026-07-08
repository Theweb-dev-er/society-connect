"""
Celery tasks for accounts app.
"""

import logging

from celery import shared_task
from django.conf import settings

from .utils import send_otp_sms

logger = logging.getLogger("apps.accounts")


@shared_task(bind=True, max_retries=3)
def send_otp_async(self, phone, code):
    """Send OTP via SMS asynchronously."""
    try:
        result = send_otp_sms(phone, code)
        if result:
            logger.info(f"[Celery] OTP sent to {phone}")
            return {"status": "sent", "phone": phone}
        else:
            logger.warning(f"[Celery] OTP send failed for {phone}")
            return {"status": "failed", "phone": phone}
    except Exception as exc:
        logger.error(f"[Celery] OTP send error: {exc}")
        raise self.retry(exc=exc, countdown=60)
