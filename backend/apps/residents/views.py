"""
Resident views.
"""

from django.db import transaction
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsAdmin, IsAdminOrMaker
from apps.core.pagination import CursorPagination

from .models import ResidentProfile
from .serializers import (
    ResidentProfileSerializer,
    ResidentRoleUpdateSerializer,
    ResidentAdminTransferSerializer,
    ResidentProfileCreateSerializer,
)
from apps.societies.models import Society


class ResidentListView(generics.ListAPIView):
    """List residents of the current user's society."""

    serializer_class = ResidentProfileSerializer
    permission_classes = [IsAdminOrMaker]
    pagination_class = CursorPagination

    def get_queryset(self):
        return ResidentProfile.objects.filter(
            society=self.request.user.society,
            is_primary=True
        ).select_related("user")


class ResidentRoleUpdateView(generics.GenericAPIView):
    """Update role flags for a resident (admin only)."""

    permission_classes = [IsAdmin]
    serializer_class = ResidentRoleUpdateSerializer

    def patch(self, request, pk):
        try:
            profile = ResidentProfile.objects.select_related("user").get(
                pk=pk, society=request.user.society
            )
        except ResidentProfile.DoesNotExist:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        user = profile.user
        for field in ["is_admin", "is_maker", "is_checker", "is_approver"]:
            if field in serializer.validated_data:
                setattr(user, field, serializer.validated_data[field])
        user.save()

        return Response(
            {"detail": "Roles updated successfully.", "user_id": str(user.id)},
            status=status.HTTP_200_OK,
        )


class ResidentAdminTransferView(generics.GenericAPIView):
    """Transfer admin role from one resident to another atomically."""

    permission_classes = [IsAuthenticated]
    serializer_class = ResidentAdminTransferSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from_id = serializer.validated_data["from_resident_id"]
        to_id = serializer.validated_data["to_resident_id"]
        reason = serializer.validated_data.get("reason", "")

        society = request.user.society
        if not society:
            return Response({"detail": "No society associated."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from_profile = ResidentProfile.objects.select_related("user").get(pk=from_id, society=society)
            to_profile = ResidentProfile.objects.select_related("user").get(pk=to_id, society=society)
        except ResidentProfile.DoesNotExist:
            return Response({"detail": "Resident not found."}, status=status.HTTP_404_NOT_FOUND)

        from_user = from_profile.user
        to_user = to_profile.user

        # Only the current admin can transfer their own admin, or superuser
        if not (request.user.is_admin or request.user.is_superuser):
            return Response({"detail": "Only admin can transfer admin role."}, status=status.HTTP_403_FORBIDDEN)

        if not from_user.is_admin:
            return Response({"detail": "Source resident is not an admin."}, status=status.HTTP_400_BAD_REQUEST)

        if to_user.is_admin:
            return Response({"detail": "Target resident is already an admin."}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            from_user.is_admin = False
            from_user.save()

            to_user.is_admin = True
            to_user.save()

        return Response(
            {
                "detail": "Admin transferred successfully.",
                "from": str(from_user.id),
                "to": str(to_user.id),
                "reason": reason,
            },
            status=status.HTTP_200_OK,
        )


class ResidentProfileCreateView(generics.CreateAPIView):
    """Create a resident profile for the current user."""

    permission_classes = [IsAuthenticated]
    serializer_class = ResidentProfileCreateSerializer

    def create(self, request, *args, **kwargs):
        if hasattr(request.user, "resident_profile"):
            return Response(
                {"detail": "User already has a resident profile."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        name = serializer.validated_data.pop("name", None)
        society_code = serializer.validated_data.pop("society_code", None)
        society_id = serializer.validated_data.pop("society_id", None)

        try:
            if society_code:
                society = Society.objects.get(code=society_code)
            else:
                society = Society.objects.get(id=society_id)
        except Society.DoesNotExist:
            return Response(
                {"detail": "Society not found."}, status=status.HTTP_404_NOT_FOUND
            )
            
        wing = serializer.validated_data.get("wing", "")
        flat_no = serializer.validated_data.get("flat_no", "")

        if society.wings:
            valid_wings = {w.strip().lower() for w in society.wings}
            if wing.strip().lower() not in valid_wings:
                return Response({"detail": f"Invalid wing '{wing}'. Must be one of: {', '.join(society.wings)}."}, status=status.HTTP_400_BAD_REQUEST)

        if ResidentProfile.objects.filter(society=society, wing=wing, flat_no=flat_no, is_primary=True).exists():
            return Response({"detail": f"Flat {flat_no} in Wing {wing} already has a registered owner."}, status=status.HTTP_400_BAD_REQUEST)

        # Create the resident profile
        with transaction.atomic():
            profile = ResidentProfile.objects.create(
                user=request.user, society=society, **serializer.validated_data
            )
            
            # Update user's name and society reference if not set
            user_changed = False
            if name:
                request.user.name = name
                user_changed = True
            if not request.user.society:
                request.user.society = society
                user_changed = True
            if user_changed:
                request.user.save()

        return Response(
            ResidentProfileSerializer(profile).data, status=status.HTTP_201_CREATED
        )


from rest_framework import viewsets
from .serializers import FamilyMemberSerializer, VehicleSerializer
from .models import Vehicle

class FamilyMemberViewSet(viewsets.ModelViewSet):
    serializer_class = FamilyMemberSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        try:
            profile = self.request.user.resident_profile
            return ResidentProfile.objects.filter(
                society=profile.society,
                wing=profile.wing,
                flat_no=profile.flat_no,
            ).exclude(user=self.request.user).select_related("user")
        except ResidentProfile.DoesNotExist:
            return ResidentProfile.objects.none()

class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        try:
            profile = self.request.user.resident_profile
            return Vehicle.objects.filter(
                society=profile.society,
                resident__flat_no=profile.flat_no,
                resident__wing=profile.wing,
            )
        except ResidentProfile.DoesNotExist:
            return Vehicle.objects.none()

    def perform_create(self, serializer):
        profile = self.request.user.resident_profile
        serializer.save(society=profile.society, resident=profile)
import csv
import io
from django.db import transaction
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from apps.accounts.permissions import IsAdmin
from apps.accounts.models import User
from .models import ResidentProfile

class AdminResidentAddView(APIView):
    permission_classes = [IsAdmin]

    def post(self, request, *args, **kwargs):
        name = request.data.get("name")
        phone = request.data.get("phone")
        wing = request.data.get("wing")
        flat_no = request.data.get("flat_no")
        is_owner = request.data.get("is_owner", True)
        bhk_type = request.data.get("bhk_type", "")
        
        if not all([name, phone, wing, flat_no]):
            return Response({"detail": "Name, phone, wing, and flat number are required."}, status=status.HTTP_400_BAD_REQUEST)
            
        society = request.user.society
        
        if society.wings:
            valid_wings = {w.strip().lower() for w in society.wings}
            if wing.strip().lower() not in valid_wings:
                return Response({"detail": f"Invalid wing '{wing}'. Must be one of: {', '.join(society.wings)}."}, status=status.HTTP_400_BAD_REQUEST)
                
        if len(phone) != 10 or not phone.isdigit():
            return Response({"detail": "Phone number must be exactly 10 digits."}, status=status.HTTP_400_BAD_REQUEST)
            
        if ResidentProfile.objects.filter(society=society, wing=wing, flat_no=flat_no, is_primary=True).exists():
            return Response({"detail": f"Flat {flat_no} in Wing {wing} already has a registered owner."}, status=status.HTTP_400_BAD_REQUEST)
            
        if ResidentProfile.objects.filter(society=society, user__phone=phone, is_primary=True).exists():
            return Response({"detail": f"Phone {phone} is already registered as an owner in this society."}, status=status.HTTP_400_BAD_REQUEST)
        
        with transaction.atomic():
            user, created = User.objects.get_or_create(
                phone=phone,
                defaults={"name": name, "role": "resident", "society": society}
            )
            if not created and not user.society:
                user.society = society
                user.save()
                
            profile, created = ResidentProfile.objects.get_or_create(
                user=user,
                defaults={
                    "society": society,
                    "wing": wing,
                    "flat_no": flat_no,
                    "is_owner": is_owner,
                    "bhk_type": bhk_type,
                    "is_primary": True
                }
            )
            
        return Response({"detail": "Resident added successfully."}, status=status.HTTP_201_CREATED)

class AdminResidentImportCSVView(APIView):
    permission_classes = [IsAdmin]

    def post(self, request, *args, **kwargs):
        file = request.FILES.get("file")
        if not file:
            return Response({"detail": "No file uploaded."}, status=status.HTTP_400_BAD_REQUEST)
            
        if not file.name.endswith(".csv"):
            return Response({"detail": "File must be a CSV."}, status=status.HTTP_400_BAD_REQUEST)
            
        society = request.user.society
        decoded_file = file.read().decode('utf-8')
        io_string = io.StringIO(decoded_file)
        reader = csv.DictReader(io_string)
        
        success_count = 0
        error_rows = []
        
        for row_idx, row in enumerate(reader):
            try:
                cleaned_row = {k.strip(): v for k, v in row.items() if k is not None}
                name = cleaned_row.get("Name", "").strip()
                phone = cleaned_row.get("Phone", "").strip()
                wing = cleaned_row.get("Wing", "").strip()
                flat_no = cleaned_row.get("Flat Number", "").strip()
                is_owner_str = cleaned_row.get("Is Owner", "Yes").strip().lower()
                is_owner = is_owner_str in ["yes", "y", "true", "1"]
                bhk_type = cleaned_row.get("BHK", "").strip()
                
                if not all([name, phone, wing, flat_no]):
                    error_rows.append(f"Row {row_idx + 2}: Missing required fields.")
                    continue
                    
                if society.wings:
                    valid_wings = {w.strip().lower() for w in society.wings}
                    if wing.lower() not in valid_wings:
                        error_rows.append(f"Row {row_idx + 2}: Invalid wing '{wing}'. Must be one of: {', '.join(society.wings)}.")
                        continue
                        
                if len(phone) != 10 or not phone.isdigit():
                    error_rows.append(f"Row {row_idx + 2}: Phone number must be exactly 10 digits.")
                    continue
                    
                if ResidentProfile.objects.filter(society=society, wing=wing, flat_no=flat_no, is_primary=True).exists():
                    error_rows.append(f"Row {row_idx + 2}: Flat {flat_no} in Wing {wing} already has a registered owner.")
                    continue
                    
                valid_bhk_types = {c[0] for c in ResidentProfile.BHK_CHOICES}
                if bhk_type and bhk_type not in valid_bhk_types:
                    error_rows.append(f"Row {row_idx + 2}: Invalid BHK '{bhk_type}'. Must be one of: {', '.join(valid_bhk_types)}.")
                    continue
                    
                if ResidentProfile.objects.filter(society=society, user__phone=phone, is_primary=True).exists():
                    error_rows.append(f"Row {row_idx + 2}: Phone {phone} is already registered as an owner in this society.")
                    continue
                    
                with transaction.atomic():
                    user, created = User.objects.get_or_create(
                        phone=phone,
                        defaults={"name": name, "role": "resident", "society": society}
                    )
                    if not created and not user.society:
                        user.society = society
                        user.save()
                        
                    profile, p_created = ResidentProfile.objects.get_or_create(
                        user=user,
                        defaults={
                            "society": society,
                            "wing": wing,
                            "flat_no": flat_no,
                            "is_owner": is_owner,
                            "bhk_type": bhk_type,
                            "is_primary": True
                        }
                    )
                success_count += 1
            except Exception as e:
                error_rows.append(f"Row {row_idx + 2}: {str(e)}")
                
        return Response({
            "detail": f"Import complete. Added {success_count} residents.",
            "success_count": success_count,
            "errors": error_rows
        }, status=status.HTTP_200_OK)
