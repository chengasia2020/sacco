from django.urls import path, include
from rest_framework.routers import DefaultRouter

from apps.transactions.views import TransactionViewSet, TransactionFeeViewSet, TransactionLimitViewSet

router = DefaultRouter()
router.register(r'transactions', TransactionViewSet, basename='transactions')
router.register(r'fees', TransactionFeeViewSet, basename='transaction-fees')
router.register(r'limits', TransactionLimitViewSet, basename='transaction-limits')

urlpatterns = [
    path('', include(router.urls)),
]