"""
Society views.
"""

import random
import string
from django.db import transaction
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User
from apps.billing.models import BillCategory
from apps.residents.models import ResidentProfile

from .models import Society
from .serializers import SocietySerializer, SocietyRegistrationSerializer


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


class CheckPhoneView(APIView):
    """Check if a phone number is already registered."""

    permission_classes = [permissions.AllowAny]

    def post(self, request):
        phone = request.data.get('phone', '').strip()
        if not phone:
            return Response(
                {"error": "Phone number is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        exists = User.objects.filter(phone=phone).exists()
        return Response({"exists": exists}, status=status.HTTP_200_OK)


class SocietyRegistrationView(APIView):
    """Register a new society and its admin/owner."""
    
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SocietyRegistrationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        
        # Check if user already exists
        if User.objects.filter(phone=data['owner']['phone']).exists():
            return Response(
                {"error": "User with this phone number already exists."},
                status=status.HTTP_400_BAD_REQUEST
            )

        with transaction.atomic():
            # Generate unique code
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
            while Society.objects.filter(code=code).exists():
                code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

            # Create Society
            society = Society.objects.create(
                name=data['name'],
                code=code,
                address=data.get('address', ''),
                total_flats=data['total_flats'],
                wings=data['wings'],
                bhk_types=data.get('bhk_types', []),
            )

            # Create default billing categories
            default_categories = [
                ("Water Charges", "Monthly water supply charges", 1),
                ("Electricity Bill", "Common area electricity charges", 2),
                ("Security Charges", "Security guard and maintenance charges", 3),
            ]
            for name, description, order in default_categories:
                BillCategory.objects.create(
                    society=society,
                    name=name,
                    description=description,
                    order=order,
                    is_active=True,
                )

            # Create User (Admin/Owner)
            user = User.objects.create(
                phone=data['owner']['phone'],
                name=data['owner']['name'],
                email=data['owner'].get('email', ''),
                society=society,
                role='admin',
                is_admin=True,
                is_maker=False,
                is_checker=False,
                is_approver=False
            )

            # Generate JWT Token
            refresh = RefreshToken.for_user(user)
            
            return Response({
                "message": "Society registered successfully.",
                "society": SocietySerializer(society).data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": {
                    "id": str(user.id),
                    "name": user.name,
                    "phone": user.phone,
                    "role": user.role,
                    "is_admin": user.is_admin,
                    "society": str(society.id),
                    "society_name": society.name,
                    "society_code": society.code
                }
            }, status=status.HTTP_201_CREATED)


class SocietyByCodeView(APIView):
    """Fetch basic society details by unique code (public)."""

    permission_classes = [permissions.AllowAny]

    def get(self, request):
        code = request.query_params.get('code')
        if not code:
            return Response({"detail": "Society code is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            society = Society.objects.get(code=code)
        except Society.DoesNotExist:
            return Response({"detail": "Society not found."}, status=status.HTTP_404_NOT_FOUND)

        return Response({
            "id": str(society.id),
            "name": society.name,
            "code": society.code,
            "address": society.address,
            "wings": society.wings,
        }, status=status.HTTP_200_OK)
