from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, hour, count, sum as _sum, explode
from pyspark.sql.types import StructType, StructField, StringType, LongType, TimestampType, ArrayType
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import os


PUSHGATEWAY_URL = os.getenv("PUSHGATEWAY_URL", "prometheus-prometheus-pushgateway:9091")
KAFKA_BROKERCONNECT = os.getenv("KAFKA_BROKERCONNECT", "kafka:9092")


def process_batch(batch_df, batch_id):  

    if batch_df.rdd.isEmpty():
        print(f"Batch {batch_id} rỗng.")
        return

    agg_df = batch_df.agg(
        count("*").alias("transaction_count")
    )
    result = agg_df.collect()[0]
    transaction_count = result["transaction_count"]

    print(f"Batch {batch_id}: count = {transaction_count}")

    # Đẩy metric lên Pushgateway
    try:
        

        registry = CollectorRegistry()

        gauge_count = Gauge('transaction_count', 'Số lượng giao dịch trong batch', registry=registry)

        gauge_count.set(transaction_count)

        push_to_gateway(PUSHGATEWAY_URL, job='transaction_job', registry=registry)

        print(f"Đã đẩy metric của batch {batch_id} lên Pushgateway ({PUSHGATEWAY_URL}).")
    except Exception as e:
        print(f"Lỗi khi đẩy metric của batch {batch_id}: {e}")


def main():
    schema = StructType([
        StructField("transaction_id", StringType(), False),
        StructField("sender_account", StringType(), False),
        StructField("receiver_account", StringType(), False),
        StructField("amount", LongType(), False),
        StructField("timestamp", TimestampType(), False),
        StructField("sender_balance_before", LongType(), False),
        StructField("receiver_balance_before", LongType(), False),
    ])

    array_schema = ArrayType(schema)

    spark = SparkSession.builder.appName("TransactionStreaming").getOrCreate()
    spark.sparkContext.setLogLevel("WARN")

    df = spark.readStream.format("kafka") \
        .option("kafka.bootstrap.servers", KAFKA_BROKERCONNECT) \
        .option("subscribe", "money_transfer") \
        .option("startingOffsets", "latest") \
        .load()

    df_json = df.selectExpr("CAST(value AS STRING) as json_value") \
            .select(from_json("json_value", array_schema).alias("data_array")) \
            .select(explode("data_array").alias("data")) \
            .select("data.*")

    query = df_json.writeStream \
            .foreachBatch(process_batch) \
            .outputMode("append") \
            .start()

    query.awaitTermination()


if __name__ == "__main__":
    main()
