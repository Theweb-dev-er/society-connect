"""
Society views.
"""

from rest_framework import generics, permissions

from .models import Society
from .serializers import SocietySerializer


class SocietyListCreateView(generics.ListCreateAPIView):
    """List all societies or create a new one."""

    queryset = Society.objects.all()
    serializer_class = SocietySerializer
    permission_classes = [permissions.IsAdminUser]


class SocietyDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a society."""

    queryset = Society.objects.all()
    serializer_class = SocietySerializer
    permission_classes = [permissions.IsAdminUser]
