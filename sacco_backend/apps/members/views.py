from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from .models import Member, NextOfKin, MemberDocument
from .serializers import (
    MemberSerializer, NextOfKinSerializer, MemberDocumentSerializer,
    MemberOnboardingSerializer, KYCVerificationSerializer
)
from .services.member_service import MemberService


class MemberViewSet(viewsets.ModelViewSet):
    queryset = Member.objects.all()
    serializer_class = MemberSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.role.name in ['STAFF', 'ADMIN']:
            return Member.objects.all()
        return Member.objects.filter(user=self.request.user)

    @transaction.atomic
    def create(self, request):
        member_data = request.data.get('member', {})
        next_of_kin_data = request.data.get('next_of_kin', [])

        try:
            member = MemberService.register_member(
                request.user,
                member_data,
                next_of_kin_data
            )
            return Response(
                MemberSerializer(member).data,
                status=status.HTTP_201_CREATED
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['post'])
    def start_onboarding(self, request):
        """Start the member onboarding process."""
        serializer = MemberOnboardingSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        try:
            onboarding_data = MemberService.initiate_onboarding(
                request.user,
                serializer.validated_data
            )
            return Response(onboarding_data, status=status.HTTP_201_CREATED)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def complete_kyc(self, request, pk=None):
        """Complete KYC verification for member."""
        member = self.get_object()
        serializer = KYCVerificationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        try:
            verified_member = MemberService.complete_kyc_verification(
                member.id,
                serializer.validated_data
            )
            return Response(MemberSerializer(verified_member).data)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def onboarding_progress(self, request, pk=None):
        """Get member onboarding progress."""
        member = self.get_object()
        try:
            progress = MemberService.get_onboarding_progress(member.id)
            return Response(progress)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'])
    def me(self, request):
        member = Member.objects.filter(user=request.user).first()
        if not member:
            return Response(
                {'error': 'Member not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        return Response(MemberSerializer(member).data)

    @action(detail=True, methods=['post'])
    def upload_document(self, request, pk=None):
        member = self.get_object()
        serializer = MemberDocumentSerializer(data=request.data)

        if serializer.is_valid():
            serializer.save(member=member)
            
            # Check if this completes KYC documentation
            try:
                MemberService.check_kyc_completion(member.id)
            except:
                pass  # Continue even if KYC check fails
                
            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED
            )
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    @action(detail=True, methods=['post'])
    def verify_document(self, request, pk=None):
        """Verify a member's uploaded document."""
        member = self.get_object()
        document_id = request.data.get('document_id')
        verification_status = request.data.get('status')  # 'VERIFIED' or 'REJECTED'
        notes = request.data.get('notes', '')
        
        if not document_id or not verification_status:
            return Response(
                {'error': 'document_id and status are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            document = MemberService.verify_document(
                document_id, verification_status, notes, request.user
            )
            return Response(MemberDocumentSerializer(document).data)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        member = self.get_object()
        new_status = request.data.get('status')
        reason = request.data.get('reason', '')

        if not new_status:
            return Response(
                {'error': 'Status is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            updated_member = MemberService.update_member_status(
                member.id, new_status, reason, request.user
            )
            return Response(MemberSerializer(updated_member).data)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        """Activate a member after successful onboarding."""
        member = self.get_object()
        
        try:
            activated_member = MemberService.activate_member(member.id, request.user)
            return Response({
                'status': 'Member activated successfully',
                'member': MemberSerializer(activated_member).data
            })
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'])
    def financial_summary(self, request, pk=None):
        """Get member's financial summary."""
        member = self.get_object()
        
        try:
            summary = MemberService.get_financial_summary(member.id)
            return Response(summary)
        except ValueError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class NextOfKinViewSet(viewsets.ModelViewSet):
    queryset = NextOfKin.objects.all()
    serializer_class = NextOfKinSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return NextOfKin.objects.filter(member__user=self.request.user)
