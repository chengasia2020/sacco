# apps/savings/serializers.py
from decimal import Decimal
from rest_framework import serializers

from apps.savings.models import SavingsAccount, SavingsTransaction, InterestRate


class SavingsAccountSerializer(serializers.ModelSerializer):
    member_name = serializers.CharField(source='member.full_name', read_only=True)
    
    class Meta:
        model = SavingsAccount
        fields = '__all__'
        read_only_fields = ['balance', 'last_interest_date', 'account_number', 'date_opened']


class SavingsTransactionSerializer(serializers.ModelSerializer):
    account_number = serializers.CharField(source='account.account_number', read_only=True)
    
    class Meta:
        model = SavingsTransaction
        fields = '__all__'
        read_only_fields = ['balance_after', 'reference', 'date']


class InterestRateSerializer(serializers.ModelSerializer):
    class Meta:
        model = InterestRate
        fields = '__all__'


class AccountOpeningSerializer(serializers.Serializer):
    member = serializers.IntegerField()
    account_type = serializers.ChoiceField(choices=SavingsAccount.ACCOUNT_TYPES)
    initial_deposit = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=Decimal('0'))


