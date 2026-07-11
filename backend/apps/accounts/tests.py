from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.accounts.models import User, DeviceToken


class DeviceTokenTests(APITestCase):

    def setUp(self):
        # Create test users
        self.user1 = User.objects.create_user(phone="9999999991", password="password123", name="User One")
        self.user2 = User.objects.create_user(phone="9999999992", password="password123", name="User Two")
        self.url = reverse("device-tokens")

    def test_register_device_token_unauthenticated(self):
        """Unauthenticated requests should be blocked."""
        response = self.client.post(self.url, {"token": "test-token-123", "device_type": "android"})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


    def test_register_device_token_success(self):
        """Authenticate and register a new token."""
        self.client.force_authenticate(user=self.user1)
        response = self.client.post(self.url, {"token": "test-token-123", "device_type": "android"})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(DeviceToken.objects.count(), 1)

        device_token = DeviceToken.objects.first()
        self.assertEqual(device_token.token, "test-token-123")
        self.assertEqual(device_token.user, self.user1)
        self.assertEqual(device_token.device_type, "android")

    def test_reregister_existing_token_transfers_user(self):
        """If a token is registered by user1, then user2 registers the same token, it transfers to user2."""
        # User 1 registers token
        DeviceToken.objects.create(user=self.user1, token="shared-token", device_type="android")

        # User 2 registers the exact same token
        self.client.force_authenticate(user=self.user2)
        response = self.client.post(self.url, {"token": "shared-token", "device_type": "ios"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Check token is updated
        self.assertEqual(DeviceToken.objects.count(), 1)
        device_token = DeviceToken.objects.first()
        self.assertEqual(device_token.user, self.user2)
        self.assertEqual(device_token.device_type, "ios")

    def test_delete_device_token(self):
        """Authenticate and delete a registered token."""
        DeviceToken.objects.create(user=self.user1, token="token-to-delete", device_type="android")

        self.client.force_authenticate(user=self.user1)
        response = self.client.delete(self.url, {"token": "token-to-delete"})
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

        self.assertEqual(DeviceToken.objects.count(), 0)
