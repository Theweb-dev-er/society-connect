from unittest.mock import patch
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.accounts.models import User
from apps.societies.models import Society
from apps.residents.models import ResidentProfile
from apps.visitors.models import Visitor, GateLog


class VisitorTests(APITestCase):

    def setUp(self):
        # Create test society
        self.society = Society.objects.create(name="Test Society")

        # Create test users
        self.guard = User.objects.create_user(
            phone="8888888888",
            password="password123",
            name="Guard One",
            role="security_guard",
            society=self.society
        )
        self.resident = User.objects.create_user(
            phone="9999999999",
            password="password123",
            name="Resident One",
            role="resident",
            society=self.society
        )
        self.resident_profile = ResidentProfile.objects.create(
            user=self.resident,
            society=self.society,
            flat_no="Flat 101"
        )
        
        self.list_create_url = reverse("visitor-list")

    @patch("apps.core.tasks.send_push_notification_task.delay")
    def test_guard_creates_visitor_at_gate(self, mock_push_task):
        """Security guard logs a visitor at the gate.

        It should set status=expected, approved_by=None, and trigger notification.
        """
        self.client.force_authenticate(user=self.guard)
        data = {
            "name": "Rajesh Delivery",
            "type": "delivery",
            "flat": "Flat 101"
        }
        response = self.client.post(self.list_create_url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        visitor = Visitor.objects.first()
        self.assertIsNotNone(visitor)
        self.assertEqual(visitor.name, "Rajesh Delivery")
        self.assertEqual(visitor.status, "expected")
        self.assertIsNone(visitor.approved_by)

        # Verify notification was queued
        mock_push_task.assert_called_once()
        kwargs = mock_push_task.call_args[1]
        self.assertIn(str(self.resident.id), kwargs["user_ids"])
        self.assertEqual(kwargs["title"], "Visitor Approval Request")

    def test_resident_filters_visitors_by_flat(self):
        """Resident should only see expected visitors for their own flat."""
        # Visitor for resident's flat (Flat 101)
        visitor1 = Visitor.objects.create(
            name="Visitor One",
            type="guest",
            flat="Flat 101",
            status="expected",
            society=self.society
        )
        # Visitor for another flat (Flat 102)
        visitor2 = Visitor.objects.create(
            name="Visitor Two",
            type="guest",
            flat="Flat 102",
            status="expected",
            society=self.society
        )

        self.client.force_authenticate(user=self.resident)
        response = self.client.get(self.list_create_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        results = response.data.get("results", [])
        # Should only contain Visitor One
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["id"], str(visitor1.id))

    @patch("apps.core.tasks.send_push_notification_task.delay")
    def test_resident_allows_entry(self, mock_push_task):
        """Resident allows entry for an expected visitor."""
        visitor = Visitor.objects.create(
            name="Rajesh Delivery",
            type="delivery",
            flat="Flat 101",
            status="expected",
            society=self.society
        )
        enter_url = reverse("visitor-enter", kwargs={"pk": visitor.id})

        self.client.force_authenticate(user=self.resident)
        response = self.client.post(enter_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        visitor.refresh_from_db()
        self.assertEqual(visitor.status, "entered")
        self.assertEqual(visitor.approved_by, self.resident)

        # GateLog should be created
        self.assertTrue(GateLog.objects.filter(visitor=visitor, action="entry").exists())
