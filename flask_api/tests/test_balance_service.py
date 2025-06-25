# File: tests/test_balance_service.py

import pytest
from unittest.mock import patch, MagicMock, call, ANY
from firebase_admin import firestore

from app.services.balance_service import BalanceService

class MockFirestoreDoc:
    def __init__(self, data, exists=True):
        self._data = data
        self.exists = exists
        self.reference = MagicMock()
    
    def to_dict(self):
        return self._data

# --- Bakiye Servisi Testleri ---

@patch('app.services.balance_service.db')
def test_apply_expense_to_bank_account(mock_db):
    """
    Normal bir banka hesabına gider işlendiğinde bakiyenin doğru şekilde azaldığını test eder.
    """
    mock_account_ref = MagicMock()
    mock_account_ref.get.return_value = MockFirestoreDoc({'accountType': 'bank'})
    BalanceService._get_account_ref_by_name = MagicMock(return_value=mock_account_ref)
    
    tx_data = {"type": "expense", "amount": 100.0, "account": "Banka Hesabım"}

    BalanceService._apply_transaction_effect("user1", tx_data)

    # NİHAİ DÜZELTME: update metodunun tam olarak hangi argümanlarla çağrıldığını kontrol et
    mock_account_ref.update.assert_called_once_with({
        'currentBalance': firestore.Increment(-100.0),
        'updatedAt': ANY 
    })

@patch('app.services.balance_service.db')
def test_apply_expense_to_credit_card(mock_db):
    """
    Kredi kartına harcama yapıldığında, borcun arttığını test eder.
    """
    mock_account_ref = MagicMock()
    mock_account_ref.get.return_value = MockFirestoreDoc({'accountType': 'credit_card'})
    BalanceService._get_account_ref_by_name = MagicMock(return_value=mock_account_ref)
    tx_data = {"type": "expense", "amount": 250.0, "account": "Kredi Kartım"}

    BalanceService._apply_transaction_effect("user1", tx_data)

    mock_account_ref.update.assert_called_once_with({
        'currentBalance': firestore.Increment(-250.0),
        'updatedAt': ANY
    })

@patch('app.services.balance_service.db')
def test_apply_income_with_savings_allocation(mock_db):
    """
    Gelir işleminde tasarruf payı ayrıldığında, hesaba geçen net tutarın doğru olduğunu test eder.
    """
    mock_account_ref = MagicMock()
    mock_account_ref.get.return_value = MockFirestoreDoc({'accountType': 'bank'})
    BalanceService._get_account_ref_by_name = MagicMock(return_value=mock_account_ref)
    tx_data = {"type": "income", "amount": 1000.0, "account": "Banka Hesabım", "incomeAllocationPct": 10}

    BalanceService._apply_transaction_effect("user1", tx_data)
    
    mock_account_ref.update.assert_called_once_with({
        'currentBalance': firestore.Increment(900.0),
        'updatedAt': ANY
    })

@patch('app.services.balance_service.db')
def test_process_transfer_updates_both_accounts(mock_db):
    """
    process_transfer fonksiyonunun, kaynak ve hedef hesap bakiyelerini doğru güncellediğini test eder.
    """
    mock_transaction_obj = MagicMock()
    mock_source_ref = MagicMock()
    mock_dest_ref = MagicMock()
    
    BalanceService._get_account_ref_by_id = MagicMock(side_effect=[mock_source_ref, mock_dest_ref])
    
    mock_source_ref.get.return_value = MockFirestoreDoc({'accountType': 'bank'}, exists=True)
    mock_dest_ref.get.return_value = MockFirestoreDoc({'accountType': 'cash'}, exists=True)

    BalanceService.process_transfer(mock_transaction_obj, "user1", "source_acc_id", "dest_acc_id", 300.0)

    # Her bir update çağrısını ayrı ayrı ve tam olarak doğrula
    source_update_call = call(mock_source_ref, {'currentBalance': firestore.Increment(-300.0)})
    dest_update_call = call(mock_dest_ref, {'currentBalance': firestore.Increment(300.0)})
    
    mock_transaction_obj.update.assert_has_calls([source_update_call, dest_update_call], any_order=True)