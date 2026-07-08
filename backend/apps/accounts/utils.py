"""
OTP utilities with Redis-backed rate limiting.
"""

import hashlib
import logging
import random
import string

import redis
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger("apps.accounts")


def _redis_key(phone):
    return f"otp:{phone}"


def _rate_limit_key(phone):
    return f"otp_rate:{phone}"


def generate_otp(phone, purpose="login"):
    """Generate a 6-digit OTP and store in Redis with rate limiting."""
    # Rate limiting
    rate_key = _rate_limit_key(phone)
    attempts = cache.get(rate_key, 0)
    if attempts >= settings.OTP_RATE_LIMIT_PER_PHONE:
        raise ValueError(
            f"Too many OTP requests. Try again after {settings.OTP_RATE_LIMIT_WINDOW_SECONDS // 60} minutes."
        )

    code = "".join(random.choices(string.digits, k=settings.OTP_LENGTH))
    # Store hashed code for security
    hashed = hashlib.sha256(code.encode()).hexdigest()
    key = _redis_key(phone)
    cache.set(key, hashed, timeout=settings.OTP_EXPIRY_SECONDS)
    cache.set(rate_key, attempts + 1, timeout=settings.OTP_RATE_LIMIT_WINDOW_SECONDS)

    # Log for dev mock mode
    if settings.OTP_PROVIDER == "mock":
        logger.info(f"[MOCK OTP] Phone: {phone}, Code: {code}, Purpose: {purpose}")

    return code


def verify_otp(phone, code):
    """Verify an OTP code. Returns True if valid, False otherwise."""
    # Mock mode bypass for testing
    if settings.OTP_PROVIDER == "mock" and code == "123456":
        logger.info(f"[MOCK OTP] Test bypass used for {phone}")
        cache.delete(_redis_key(phone))
        return True

    key = _redis_key(phone)
    stored_hash = cache.get(key)
    if not stored_hash:
        return False
    hashed = hashlib.sha256(code.encode()).hexdigest()
    if hashed == stored_hash:
        cache.delete(key)
        return True
    return False


def send_otp_sms(phone, code):
    """Send OTP via configured provider."""
    if settings.OTP_PROVIDER == "mock":
        logger.info(f"[MOCK SMS] OTP {code} sent to {phone}")
        return True

    # Twilio integration
    if settings.OTP_PROVIDER == "twilio":
        try:
            from twilio.rest import Client

            client = Client(
                settings.TWILIO_ACCOUNT_SID,
                settings.TWILIO_AUTH_TOKEN,
            )
            message = client.messages.create(
                body=f"Your Society App OTP is: {code}. Valid for 5 minutes.",
                from_=settings.TWILIO_FROM_NUMBER,
                to=f"+91{phone}",  # Assuming India; make configurable
            )
            logger.info(f"[Twilio SMS] SID: {message.sid} to {phone}")
            return True
        except Exception as e:
            logger.error(f"[Twilio SMS] Failed: {e}")
            return False

    logger.warning(f"[OTP] Unknown provider: {settings.OTP_PROVIDER}")
    return False
