from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from datetime import datetime
import uuid
import random
import time
import json


names = ["0234342234", "3453452342", "5464565446", "0342342434", "4564564566", "2345234553"]

app = FastAPI()

class Transaction(BaseModel):
    transaction_id:str
    sender_account: str
    receiver_account: str
    amount: int
    timestamp: str
    sender_balance_before: int
    receiver_balance_before: int


def generate_data():
    while True:
        transfer_quantity = random.randint(1, 10)
        transfer_data_list = [] 
        
        for i in range(transfer_quantity):
            transfer_data_list.append(
                Transaction(
                    transaction_id=str(uuid.uuid4()),  
                    sender_account=random.choice(names),
                    receiver_account=random.choice(names),
                    amount=random.randint(1000, 100000000000),
                    timestamp=datetime.now().isoformat(),  # Thời gian hiện tại
                    sender_balance_before=random.randint(1000, 100000000000),
                    receiver_balance_before=random.randint(1000, 100000000000),
                ).dict()
            )

        yield f"data: {json.dumps(transfer_data_list)}\n\n"
        time.sleep(1)  


@app.get("/transfer_data")
async def get_transfer_data() :
    return StreamingResponse(generate_data(), media_type="text/event-stream")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
