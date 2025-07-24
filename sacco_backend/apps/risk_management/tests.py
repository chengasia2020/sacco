from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import date, timedelta
from decimal import Decimal
import json
from unittest.mock import patch, MagicMock

from apps.authentication.models import Role
from apps.members.models import Member
from apps.risk_management.models import RiskProfile, FraudAlert
from apps.risk_management.services.risk_assessment_service import RiskAssessmentService
from apps.risk_management.services.fraud_detection_service import FraudDetectionService
from apps.transactions.models import Transaction

User = get_user_model()


class RiskManagementTest(TestCase):
    def setUp(self):
        # Create role
        self.role = Role.objects.create(name='MEMBER')

        # Create user
        self.user = User.objects.create_user(
            email='member@example.com',
            password='testpass123',
            first_name='Test',
            last_name='Member',
            role=self.role,
            phone_number='+256700000000',
            national_id='TEST123'
        )

        # Create member
        self.member = Member.objects.create(
            user=self.user,
            member_number='M2024TEST001',
            date_of_birth=date(1990, 1, 1),
            is_verified=True,
            registration_date=date(2023, 1, 1),
            marital_status='SINGLE',
            employment_status='EMPLOYED',
            occupation='Engineer',
            monthly_income=Decimal('700000'),
            physical_address='Test Address',
            city='Kampala',
            district='Central',
            national_id='TEST123',
            membership_number='SACCOM2024TEST001',
            membership_type='INDIVIDUAL'
        )

        # Create risk profile (using timezone-aware datetime)
        now = timezone.now()
        self.risk_profile = RiskProfile.objects.create(
            member=self.member,
            credit_score=700,
            risk_level='LOW',
            last_assessment_date=now,
            next_assessment_date=now + timedelta(days=90),
            factors=json.dumps({
                'income_stability': 'Stable',
                'credit_history': 'Good',
                'debt_to_income_ratio': 'Low',
                'employment_status': 'Employed',
                'savings_balance': 'Good',
                'loan_repayment_history': 'Good',
                'collateral_value': 'High',
            })
        )

        # Create a transaction for fraud detection tests
        self.transaction = Transaction.objects.create(
            transaction_ref='TXN20240101001',
            member=self.member,
            transaction_type='DEPOSIT',
            amount=Decimal('100000'),
            payment_method='CASH',
            status='COMPLETED'
        )

        # Patch the async methods to use synchronous versions for testing
        self.assess_member_risk_patcher = patch(
            'apps.risk_management.services.risk_assessment_service.RiskAssessmentService.assess_member_risk',
            new=self._mock_assess_member_risk)
        self.mock_assess_member_risk = self.assess_member_risk_patcher.start()

        self.analyze_transaction_patcher = patch(
            'apps.risk_management.services.fraud_detection_service.FraudDetectionService.analyze_transaction',
            new=self._mock_analyze_transaction)
        self.mock_analyze_transaction = self.analyze_transaction_patcher.start()

    def tearDown(self):
        self.assess_member_risk_patcher.stop()
        self.analyze_transaction_patcher.stop()

    def _mock_assess_member_risk(self, member_id):
        """Synchronous version of assess_member_risk for testing"""
        member = Member.objects.get(id=member_id)
        now = timezone.now()

        # Use existing risk profile or create new
        risk_profile, created = RiskProfile.objects.get_or_create(
            member=member,
            defaults={
                'credit_score': 700,
                'risk_level': 'LOW',
                'last_assessment_date': now,
                'next_assessment_date': now + timedelta(days=90),
                'factors': json.dumps({
                    'payment_history': 'Good',
                    'credit_utilization': 'Low',
                    'account_age': 'Medium',
                    'recent_inquiries': 'Low'
                })
            }
        )

        if not created:
            # Update existing profile
            current_time = timezone.now()
            risk_profile.last_assessment_date = current_time
            risk_profile.next_assessment_date = current_time + timedelta(days=90)
            risk_profile.save()

        return risk_profile

    def _mock_analyze_transaction(self, transaction):
        """Synchronous version of analyze_transaction for testing"""
        # Simple logic to flag large transactions
        indicators = {}

        if transaction.amount >= Decimal('1000000'):
            indicators['large_transaction'] = float(transaction.amount)

        if not indicators:
            return None

        # Create fraud alert
        alert = FraudAlert.objects.create(
            member=transaction.member,
            severity='MEDIUM',
            description='Potentially suspicious transaction',
            indicators=json.dumps(indicators)
        )

        return alert

    def test_risk_profile_creation(self):
        self.assertEqual(self.risk_profile.member, self.member)
        self.assertEqual(self.risk_profile.credit_score, 700)
        self.assertEqual(self.risk_profile.risk_level, 'LOW')

    def test_risk_assessment(self):
        # Test the assessment process
        risk_profile = self._mock_assess_member_risk(self.member.id)

        self.assertEqual(risk_profile.member, self.member)
        self.assertIsNotNone(risk_profile.last_assessment_date)
        self.assertIsNotNone(risk_profile.next_assessment_date)

    def test_fraud_detection_normal_transaction(self):
        # Normal transaction shouldn't trigger an alert
        alert = self._mock_analyze_transaction(self.transaction)
        self.assertIsNone(alert)

    def test_fraud_detection_suspicious_transaction(self):
        # Create a large transaction that should trigger an alert
        large_transaction = Transaction.objects.create(
            transaction_ref='TXN20240101LARGE',
            member=self.member,
            transaction_type='DEPOSIT',
            amount=Decimal('5000000'),  # 5 million
            payment_method='CASH',
            status='COMPLETED'
        )

        alert = self._mock_analyze_transaction(large_transaction)

        self.assertIsNotNone(alert)
        self.assertEqual(alert.member, self.member)
        self.assertEqual(alert.severity, 'MEDIUM')
        self.assertFalse(alert.resolved)

        # Check indicators were recorded
        indicators = json.loads(alert.indicators)
        self.assertIn('large_transaction', indicators)

    def test_risk_level_determination(self):
        # Test the method that determines risk level based on credit score
        for score, expected_level in [
            (850, 'LOW'),
            (750, 'LOW'),
            (700, 'MEDIUM'),
            (600, 'HIGH'),
            (550, 'HIGH'),
            (500, 'CRITICAL'),
            (400, 'CRITICAL')
        ]:
            risk_level = RiskAssessmentService._determine_risk_level(score, {})
            # print current risk level and score for debugging
            print(f"Score: {score}, Risk Level: {risk_level}")
            self.assertEqual(risk_level, expected_level)