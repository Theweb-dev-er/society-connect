import logging
from django.conf import settings
from apps.accounts.models import DeviceToken

logger = logging.getLogger("apps.core")


def send_push_notification(user_ids, title, body, data=None):
    """Sends a push notification to a list of user IDs or a single user ID.

    If Firebase credentials are not loaded, logs the notification to the console.
    Automatically deletes invalid/unregistered device tokens from the database.
    """
    if not isinstance(user_ids, list):
        user_ids = [user_ids]

    # Filters out any None values and casts to strings
    user_ids = [str(uid) for uid in user_ids if uid is not None]
    if not user_ids:
        return

    # Get active tokens for users
    tokens_qs = DeviceToken.objects.filter(user_id__in=user_ids)
    if not tokens_qs.exists():
        logger.info(f"[FCM Mock] No registered device tokens for users: {user_ids}")
        return

    tokens = list(tokens_qs.values_list("token", flat=True))

    # Check if FCM is initialized
    fcm_initialized = False
    try:
        import firebase_admin

        fcm_initialized = len(firebase_admin._apps) > 0
    except ImportError:
        pass

    if not fcm_initialized:
        # Mock mode: Log notifications
        logger.info(
            f"[FCM Mock] Sending notification to users {user_ids} (tokens: {tokens}):\n"
            f"Title: {title}\n"
            f"Body: {body}\n"
            f"Data: {data}"
        )
        return

    from firebase_admin import messaging

    # Construct the message payload
    message_data = {}
    if data:
        # FCM data keys and values must be strings
        message_data = {str(k): str(v) for k, v in data.items()}

    multicast_message = messaging.MulticastMessage(
        tokens=tokens,
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=message_data,
    )

    try:
        # Send notifications
        response = messaging.send_each_for_multicast(multicast_message)
        logger.info(
            f"[FCM] Sent message to {len(tokens)} devices: "
            f"{response.success_count} success, {response.failure_count} failure"
        )

        # Handle unregistered/invalid tokens by deleting them
        if response.failure_count > 0:
            tokens_to_delete = []
            for idx, resp in enumerate(response.responses):
                if not resp.success:
                    # check if error was due to expired or unregistered token
                    if resp.exception and hasattr(resp.exception, "code"):
                        err_code = resp.exception.code
                        if err_code in ["UNREGISTERED", "INVALID_ARGUMENT"]:
                            tokens_to_delete.append(tokens[idx])

            if tokens_to_delete:
                deleted_count, _ = DeviceToken.objects.filter(token__in=tokens_to_delete).delete()
                logger.info(f"[FCM] Cleaned up {deleted_count} unregistered/invalid tokens.")

    except Exception as e:
        logger.error(f"[FCM] Error sending multicast message: {e}")
