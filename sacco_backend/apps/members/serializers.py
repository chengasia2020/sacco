from rest_framework import serializers
from .models import Member, NextOfKin, MemberDocument

class NextOfKinSerializer(serializers.ModelSerializer):
    class Meta:
        model = NextOfKin
        fields = '__all__'
        read_only_fields = ['member']

class MemberDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = MemberDocument
        fields = '__all__'
        read_only_fields = ['member', 'is_verified', 'verified_by', 'verified_at']

class MemberSerializer(serializers.ModelSerializer):
    next_of_kin = NextOfKinSerializer(many=True, read_only=True)
    documents = MemberDocumentSerializer(many=True, read_only=True)

    class Meta:
        model = Member
        fields = '__all__'
        read_only_fields = ['user', 'member_number', 'registration_date']


class MemberOnboardingSerializer(serializers.Serializer):
    """Serializer for starting member onboarding process."""
    first_name = serializers.CharField(max_length=100)
    last_name = serializers.CharField(max_length=100)
    national_id = serializers.CharField(max_length=20)
    phone_number = serializers.CharField(max_length=15)
    email = serializers.EmailField()
    date_of_birth = serializers.DateField()
    gender = serializers.ChoiceField(choices=[('M', 'Male'), ('F', 'Female')])
    address = serializers.CharField(max_length=255)
    employment_status = serializers.CharField(max_length=50)
    monthly_income = serializers.DecimalField(max_digits=12, decimal_places=2)
    
    # Next of kin information
    next_of_kin_name = serializers.CharField(max_length=200)
    next_of_kin_relationship = serializers.CharField(max_length=50)
    next_of_kin_phone = serializers.CharField(max_length=15)
    next_of_kin_address = serializers.CharField(max_length=255)


class KYCVerificationSerializer(serializers.Serializer):
    """Serializer for KYC verification process."""
    identity_verified = serializers.BooleanField()
    address_verified = serializers.BooleanField()
    employment_verified = serializers.BooleanField()
    income_verified = serializers.BooleanField()
    verification_notes = serializers.CharField(max_length=500, required=False)
    
    def validate(self, data):
        required_verifications = ['identity_verified', 'address_verified', 'employment_verified']
        for field in required_verifications:
            if not data.get(field, False):
                raise serializers.ValidationError(f"{field} must be completed for KYC verification")
        return data


class MemberStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating member status."""
    status = serializers.ChoiceField(choices=[
        ('PENDING', 'Pending'),
        ('ACTIVE', 'Active'),
        ('SUSPENDED', 'Suspended'),
        ('CLOSED', 'Closed')
    ])
    reason = serializers.CharField(max_length=255, required=False)


class DocumentVerificationSerializer(serializers.Serializer):
    """Serializer for document verification."""
    document_id = serializers.IntegerField()
    status = serializers.ChoiceField(choices=[('VERIFIED', 'Verified'), ('REJECTED', 'Rejected')])
    notes = serializers.CharField(max_length=500, required=False)