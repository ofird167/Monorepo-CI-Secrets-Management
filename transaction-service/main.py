import os
import uvicorn
from fastapi import FastAPI

app = FastAPI(title="Transaction Service")


@app.get("/health")
def health():
    return {
        "status": "UP",
        "service": "transaction-service"
    }


@app.get("/api/transactions")
def get_transactions():
    return [
        {"id": 101, "amount": 250.00, "status": "COMPLETED"},
        {"id": 102, "amount": 89.90, "status": "PENDING"}
    ]


if __name__ == "__main__":
    # In production/docker, host will be 0.0.0.0.
    # In testing/local it defaults to 127.0.0.1.
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host=host, port=port)
