from main import health, get_transactions

def test_health():
    response = health()
    assert response["status"] == "UP"
    assert response["service"] == "transaction-service"

def test_get_transactions():
    transactions = get_transactions()
    assert len(transactions) == 2
    assert transactions[0]["amount"] == 250.00
    assert transactions[1]["status"] == "PENDING"
