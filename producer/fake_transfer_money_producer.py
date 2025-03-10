from kafka import KafkaProducer
import os
import json
import requests
from sseclient import SSEClient


KAFKA_BROKERCONNECT = os.getenv("KAFKA_BROKERCONNECT", "kafka:9092")
SSE_API_URL = os.getenv("SSE_API_URL", "http://fake-transfer-money-api:5000/transfer_data")


producer = KafkaProducer(
    bootstrap_servers = KAFKA_BROKERCONNECT,
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)


def send_to_kafka(topic_name, data):
    producer.send(topic_name, data)
    producer.flush()
    print("Send to Kafka: ", data)


def main():
    # session = requests.Session()
    # response = session.get(SSE_API_URL, stream=True)

    # client = sseclient.SSEClient(response)
    
    # print("Producer is listening...")

    # for event in client.events():

    messages = SSEClient(SSE_API_URL)

    for message in messages:    
        try:
            data = json.loads(message.data)
            send_to_kafka("money_transfer", data)
            # phan money transfer nen de thanh bien luu tru
        except Exception as e:
            print(e)


if __name__ == '__main__':
    main()