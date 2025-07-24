from datetime import date
# shared/services/ledger_service.py
from decimal import Decimal
from typing import Optional

from django.db import transaction

from apps.ledger.models import LedgerEntry
from apps.loans.models import LoanRepayment, Loan
from apps.transactions.models import Transaction


class LedgerService:
    ACCOUNT_CODES = {
        'CASH': '1000',
        'SAVINGS': '2000',
        'FEES_INCOME': '4000',
        'LOAN_RECEIVABLE': '1100',
        'INTEREST_INCOME': '4100'
    }

    @staticmethod
    @transaction.atomic
    def create_deposit_entries(_transaction: Transaction, fee: Decimal) -> None:
        # Get current balances
        cash_balance = LedgerService._get_account_balance(LedgerService.ACCOUNT_CODES['CASH'])
        savings_balance = LedgerService._get_account_balance(LedgerService.ACCOUNT_CODES['SAVINGS'])
        fees_balance = LedgerService._get_account_balance(LedgerService.ACCOUNT_CODES['FEES_INCOME'])

        # Debit cash/bank account
        LedgerEntry.objects.create(
            transaction=_transaction,
            account_code=LedgerService.ACCOUNT_CODES['CASH'],
            entry_type='DEBIT',
            amount=_transaction.amount,
            balance_after=cash_balance + _transaction.amount,
            description=f"Cash deposit {_transaction.transaction_ref}"
        )

        # Credit member savings account
        net_amount = _transaction.amount - fee
        LedgerEntry.objects.create(
            transaction=_transaction,
            account_code=LedgerService.ACCOUNT_CODES['SAVINGS'],
            entry_type='CREDIT',
            amount=net_amount,
            balance_after=savings_balance + net_amount,
            description=f"Savings deposit {_transaction.transaction_ref}"
        )

        if fee > 0:
            LedgerEntry.objects.create(
                transaction=_transaction,
                account_code=LedgerService.ACCOUNT_CODES['FEES_INCOME'],
                entry_type='CREDIT',
                amount=fee,
                balance_after=fees_balance + fee,
                description=f"Deposit fee {_transaction.transaction_ref}"
            )

    @staticmethod
    @transaction.atomic
    def create_withdrawal_entries(_transaction: Transaction, fee: Decimal) -> None:
        # Get current balances
        cash_balance = LedgerService._get_account_balance(LedgerService.ACCOUNT_CODES['CASH'])
        savings_balance = LedgerService._get_account_balance(LedgerService.ACCOUNT_CODES['SAVINGS'])
        fees_balance = LedgerService._get_account_balance(LedgerService.ACCOUNT_CODES['FEES_INCOME'])

        # Credit cash/bank account
        LedgerEntry.objects.create(
            transaction=_transaction,
            account_code=LedgerService.ACCOUNT_CODES['CASH'],
            entry_type='CREDIT',
            amount=_transaction.amount,
            balance_after=cash_balance - _transaction.amount,
            description=f"Cash withdrawal {_transaction.transaction_ref}"
        )

        # Debit member savings account
        total_amount = _transaction.amount + fee
        LedgerEntry.objects.create(
            transaction=_transaction,
            account_code=LedgerService.ACCOUNT_CODES['SAVINGS'],
            entry_type='DEBIT',
            amount=total_amount,
            balance_after=savings_balance - total_amount,
            description=f"Savings withdrawal {_transaction.transaction_ref}"
        )

        if fee > 0:
            LedgerEntry.objects.create(
                transaction=_transaction,
                account_code=LedgerService.ACCOUNT_CODES['FEES_INCOME'],
                entry_type='CREDIT',
                amount=fee,
                balance_after=fees_balance + fee,
                description=f"Withdrawal fee {_transaction.transaction_ref}"
            )

    @staticmethod
    def _get_account_balance(account_code: str) -> Decimal:
        """Get the current balance for an account code."""
        latest_entry = LedgerEntry.objects.filter(
            account_code=account_code
        ).order_by('-created_at').first()
        
        return latest_entry.balance_after if latest_entry else Decimal('0')

    @staticmethod
    @transaction.atomic
    def create_loan_disbursement_entries(loan: 'Loan') -> None:
        LedgerEntry.objects.create(
            transaction=loan.disbursement_transaction,
            account_code=LedgerService.ACCOUNT_CODES['LOAN_RECEIVABLE'],
            entry_type='DEBIT',
            amount=loan.amount,
            description=f"Loan disbursement - {loan.reference}"
        )

        LedgerEntry.objects.create(
            transaction=loan.disbursement_transaction,
            account_code=LedgerService.ACCOUNT_CODES['CASH'],
            entry_type='CREDIT',
            amount=loan.amount,
            description=f"Loan disbursement - {loan.reference}"
        )

    @staticmethod
    @transaction.atomic
    def create_loan_repayment_entries(repayment: 'LoanRepayment') -> None:
        LedgerEntry.objects.create(
            transaction=repayment.transaction,
            account_code=LedgerService.ACCOUNT_CODES['CASH'],
            entry_type='DEBIT',
            amount=repayment.amount,
            description=f"Loan repayment - {repayment.reference}"
        )

        LedgerEntry.objects.bulk_create([
            LedgerEntry(
                transaction=repayment.transaction,
                account_code=LedgerService.ACCOUNT_CODES['LOAN_RECEIVABLE'],
                entry_type='CREDIT',
                amount=repayment.principal_component,
                description=f"Loan principal repayment - {repayment.reference}"
            ),
            LedgerEntry(
                transaction=repayment.transaction,
                account_code=LedgerService.ACCOUNT_CODES['INTEREST_INCOME'],
                entry_type='CREDIT',
                amount=repayment.interest_component,
                description=f"Loan interest payment - {repayment.reference}"
            )
        ])

    @staticmethod
    def get_account_balance(account_code: str, as_of_date: Optional[date] = None) -> Decimal:
        """Calculate account balance as of specified date"""
        query = LedgerEntry.objects.filter(account_code=account_code)

        if as_of_date:
            query = query.filter(created_at__lte=as_of_date)

        balance = Decimal('0')
        for entry in query.iterator():
            if entry.entry_type == 'DEBIT':
                balance += entry.amount
            else:
                balance -= entry.amount

        return balance

    @staticmethod
    def generate_trial_balance(start_date: date, end_date: date) -> dict:
        """Generate trial balance for specified period"""
        accounts = {}

        # Get all entries within date range
        entries = LedgerEntry.objects.filter(
            created_at__range=[start_date, end_date]
        ).select_related('transaction')

        # Calculate totals for each account
        for entry in entries:
            if entry.account_code not in accounts:
                accounts[entry.account_code] = {
                    'account_name': LedgerService.ACCOUNT_CODES.get(entry.account_code, 'Unknown'),
                    'debit_total': Decimal('0'),
                    'credit_total': Decimal('0'),
                    'net_balance': Decimal('0')
                }

            if entry.entry_type == 'DEBIT':
                accounts[entry.account_code]['debit_total'] += entry.amount
                accounts[entry.account_code]['net_balance'] += entry.amount
            else:
                accounts[entry.account_code]['credit_total'] += entry.amount
                accounts[entry.account_code]['net_balance'] -= entry.amount

        # Calculate totals
        total_debits = sum(acc['debit_total'] for acc in accounts.values())
        total_credits = sum(acc['credit_total'] for acc in accounts.values())
        net_balance = sum(acc['net_balance'] for acc in accounts.values())

        return {
            'accounts': [
                {
                    'account_code': code,
                    **account_data
                }
                for code, account_data in accounts.items()
            ],
            'totals': {
                'total_debits': total_debits,
                'total_credits': total_credits,
                'net_balance': net_balance
            },
            'period': {
                'start_date': start_date,
                'end_date': end_date
            }
        }
