echo ">> logging into dockerhub"
docker login -u grunklestan

echo ">> Buiding and pushing docker images..."

echo ">> Tranfer Api"
cd fastapi_generate_data
docker build -t grunklestan/fastapi_generate_data:latest .
docker push grunklestan/fastapi_generate_data:latest

echo ">> Money Transfer Kafka Producer"
cd ../producer
docker build -t grunklestan/money_transfer_producer:latest .
docker push grunklestan/money_transfer_producer:latest
