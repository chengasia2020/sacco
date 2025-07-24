from datetime import datetime

from django.contrib.auth import get_user_model
from django.template import Template, Context

from shared.services.email_service import EmailService
from shared.services.push_notification_service import PushNotificationService
from shared.services.sms_service import SMSService
from .channels import EmailChannel, SMSChannel, PushChannel
from ..models import Notification, NotificationTemplate, NotificationPreference
from ...members.models import Member
from ...risk_management.models import FraudAlert
from ...risk_management.utils.alert_utils import generate_alert_description
from ...transactions.models import Transaction

User = get_user_model()

class NotificationService:
    channels = {
        'email': EmailChannel(),
        'sms': SMSChannel(),
        'push': PushChannel()
    }

    @classmethod
    def send_notification(cls, member, template_code, context=None):
        template = NotificationTemplate.objects.get(code=template_code)
        preferences = NotificationPreference.objects.get(member=member)

        title = Template(template.title_template).render(Context(context or {}))
        message = Template(template.message_template).render(Context(context or {}))

        notification = Notification.objects.create(
            member=member,
            type=template.notification_type,
            title=title,
            message=message,
            priority=template.priority
        )

        for channel in template.channels:
            if cls._should_send_via_channel(preferences, channel):
                cls.channels[channel].send(notification)

        return notification

    @classmethod
    def _should_send_via_channel(cls, preferences, channel):
        if channel == 'email':
            return preferences.email_enabled
        elif channel == 'sms':
            return preferences.sms_enabled
        elif channel == 'push':
            return preferences.push_enabled
        return False

    @staticmethod
    async def notify_compliance_officer(alert_type: str, data: dict) -> None:
        officers = await User.objects.filter(role__name='COMPLIANCE_OFFICER').all()

        notification_data = {
            'type': alert_type,
            'title': 'Compliance Alert',
            'message': f"High-value transaction detected: {data['transaction_id']}",
            'priority': 'HIGH'
        }

        for officer in officers:
            await Notification.objects.acreate(
                user=officer,
                **notification_data
            )

    @staticmethod
    async def send_fraud_alert(alert: FraudAlert) -> None:
        notification_data = {
            'type': 'FRAUD_ALERT',
            'title': f"Fraud Alert - {alert.severity}",
            'message': generate_alert_description(alert.indicators),
            'priority': 'HIGH'
        }

        # Notify risk officers
        officers = await User.objects.filter(role__name='RISK_OFFICER').all()
        for officer in officers:
            await Notification.objects.acreate(
                user=officer,
                **notification_data
            )

    @staticmethod
    async def schedule_statement_delivery(member: Member, channel: str, request_time: datetime) -> None:
        """Schedule statement delivery via specified channel"""
        statement_data = {
            'member_id': member.id,
            'channel': channel,
            'request_time': request_time.isoformat(),
            'delivery_status': 'PENDING'
        }

        # Create notification record
        await Notification.objects.acreate(
            member=member,
            type='STATEMENT_REQUEST',
            title='Statement Request',
            message=f'Statement requested via {channel}',
            priority='LOW',
            data=statement_data
        )

        # Schedule background task for processing
        # generate_and_send_statement.delay(
        #     member_id=member.id,
        #     channel=channel,
        #     request_time=request_time.isoformat()
        # )

    @staticmethod
    async def send_loan_approval_notification(member: Member) -> None:
        """Send loan approval notification to member"""
        notification_data = {
            'title': 'Loan Approved',
            'message': 'Your loan application has been approved! Disbursement will be processed shortly.',
            'priority': 'HIGH',
            'channels': ['SMS', 'EMAIL', 'PUSH']
        }

        # Create notification
        notification = await Notification.objects.acreate(
            member=member,
            type='LOAN_APPROVAL',
            **notification_data
        )

        # Send via SMS
        if member.user.phone_number:
            await SMSService.send_message(
                member.user.phone_number,
                notification_data['message']
            )

        # Send via email
        if member.user.email:
            await EmailService.send_email(
                member.user.email,
                notification_data['title'],
                'loan_approval.html',
                {
                    'member_name': member.user.get_full_name(),
                    'message': notification_data['message']
                }
            )

        # Send push notification if device token exists
        if member.device_token:
            await PushNotificationService.send_notification(
                member.device_token,
                notification_data
            )

    @staticmethod
    async def send_loan_disbursement_notification(member: Member) -> None:
        """Send loan disbursement notification to member"""
        notification_data = {
            'title': 'Loan Disbursed',
            'message': 'Your loan has been disbursed to your account. Please check your balance.',
            'priority': 'HIGH',
            'channels': ['SMS', 'EMAIL', 'PUSH']
        }

        # Create notification record
        notification = await Notification.objects.acreate(
            member=member,
            type='LOAN_DISBURSEMENT',
            **notification_data
        )

        # Send SMS notification
        if member.user.phone_number:
            await SMSService.send_message(
                member.user.phone_number,
                notification_data['message']
            )

        # Send email notification with more details
        if member.user.email:
            await EmailService.send_email(
                member.user.email,
                notification_data['title'],
                'loan_disbursement.html',
                {
                    'member_name': member.user.get_full_name(),
                    'message': notification_data['message'],
                    'account_number': member.savings_account.account_number
                }
            )

        # Send push notification
        if member.device_token:
            await PushNotificationService.send_notification(
                member.device_token,
                notification_data
            )

    @classmethod
    def send_transaction_notification(cls, _transaction: Transaction) -> None:
        notification_data = {
            'type': 'TRANSACTION',
            'title': 'Transaction Alert',
            'message': f"Transaction of {str(_transaction.amount)} processed",
            'priority': 'NORMAL'
        }

        cls.send_notification(_transaction.member, notification_data)

    @staticmethod
    def send_loan_approval_notification_sync(member: Member) -> None:
        """Synchronous version for use in business logic"""
        try:
            # Create notification record synchronously
            notification = Notification.objects.create(
                member=member,
                type='LOAN_APPROVAL',
                title='Loan Approved',
                message='Your loan application has been approved! Disbursement will be processed shortly.',
                priority='HIGH'
            )
            
            # In a real application, you would queue this for async processing
            # For now, we'll just create the notification record
            # send_loan_approval_notification.delay(member.id)
            
        except Exception as e:
            # Log error but don't fail the loan approval process
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to send loan approval notification: {str(e)}")

    @staticmethod
    def send_loan_disbursement_notification_sync(member: Member) -> None:
        """Synchronous version for use in business logic"""
        try:
            # Create notification record synchronously
            notification = Notification.objects.create(
                member=member,
                type='LOAN_DISBURSEMENT',
                title='Loan Disbursed',
                message='Your loan has been disbursed to your account. Please check your balance.',
                priority='HIGH'
            )
            
            # In a real application, you would queue this for async processing
            # For now, we'll just create the notification record
            # send_loan_disbursement_notification.delay(member.id)
            
        except Exception as e:
            # Log error but don't fail the loan disbursement process
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to send loan disbursement notification: {str(e)}")
