from django.conf import settings
from decimal import Decimal
from django.core.validators import MinValueValidator
from django.db import models

from apps import savings


class Member(models.Model):
    MARITAL_STATUS_CHOICES = [
        ('SINGLE', 'Single'),
        ('MARRIED', 'Married'),
        ('DIVORCED', 'Divorced'),
        ('WIDOWED', 'Widowed')
    ]

    EMPLOYMENT_STATUS_CHOICES = [
        ('EMPLOYED', 'Employed'),
        ('SELF_EMPLOYED', 'Self Employed'),
        ('UNEMPLOYED', 'Unemployed'),
        ('RETIRED', 'Retired'),
        ('STUDENT', 'Student'),
        ('OTHER', 'Other')
    ]

    MEMBER_TYPES = [
        ('INDIVIDUAL', 'Individual'),
        ('JOINT', 'Joint'),
        ('CORPORATE', 'Corporate')
    ]

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    member_number = models.CharField(max_length=20, unique=True)
    date_of_birth = models.DateField()
    marital_status = models.CharField(max_length=20, choices=MARITAL_STATUS_CHOICES)
    employment_status = models.CharField(max_length=20, choices=EMPLOYMENT_STATUS_CHOICES)
    occupation = models.CharField(max_length=100)
    monthly_income = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0'))]
    )
    savings_account = models.OneToOneField(
        'savings.SavingsAccount',
        on_delete=models.PROTECT,
        null=True,
        related_name='primary_member'  # Changed from 'member'
    )

    # Address Information
    physical_address = models.TextField()
    postal_address = models.CharField(max_length=100, null=True, blank=True)
    city = models.CharField(max_length=100)
    district = models.CharField(max_length=100)

    # KYC Information
    national_id = models.CharField(max_length=20, unique=True)
    passport_photo = models.ImageField(upload_to='member_photos/', null=True)
    id_document = models.FileField(upload_to='member_documents/', null=True)
    device_token = models.CharField(max_length=255, null=True, blank=True)
    is_verified = models.BooleanField(default=False)

    # Membership Information
    registration_date = models.DateField(auto_now_add=True)
    membership_status = models.CharField(max_length=20, default='ACTIVE')
    membership_number = models.CharField(max_length=20, unique=True)
    membership_type = models.CharField(max_length=20, choices=MEMBER_TYPES)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.member_number} - {self.user.get_full_name()}"


class NextOfKin(models.Model):
    RELATIONSHIP_CHOICES = [
        ('SPOUSE', 'Spouse'),
        ('CHILD', 'Child'),
        ('PARENT', 'Parent'),
        ('SIBLING', 'Sibling'),
        ('OTHER', 'Other')
    ]

    member = models.ForeignKey(Member, on_delete=models.CASCADE, related_name='next_of_kin')
    full_name = models.CharField(max_length=100)
    relationship = models.CharField(max_length=20, choices=RELATIONSHIP_CHOICES)
    phone_number = models.CharField(max_length=15)
    email = models.EmailField(null=True, blank=True)
    physical_address = models.TextField()
    national_id = models.CharField(max_length=20)
    percentage_share = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0'))]
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.full_name} - {self.relationship} of {self.member.user.get_full_name()}"


class MemberDocument(models.Model):
    DOCUMENT_TYPES = [
        ('ID', 'National ID'),
        ('PASSPORT', 'Passport'),
        ('UTILITY_BILL', 'Utility Bill'),
        ('BANK_STATEMENT', 'Bank Statement'),
        ('OTHER', 'Other')
    ]

    member = models.ForeignKey(Member, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=20, choices=DOCUMENT_TYPES)
    document = models.FileField(upload_to='member_documents/')
    description = models.TextField(null=True, blank=True)
    is_verified = models.BooleanField(default=False)
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='verified_documents'
    )
    verified_at = models.DateTimeField(null=True, blank=True)

    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.document_type} - {self.member.user.get_full_name()}"
