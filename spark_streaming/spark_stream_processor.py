from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, hour, count, sum as _sum, explode
from pyspark.sql.types import StructType, StructField, StringType, LongType, TimestampType, ArrayType
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import os


PUSHGATEWAY_URL = os.getenv("PUSHGATEWAY_URL", "prometheus-prometheus-pushgateway:9091")
KAFKA_BROKERCONNECT = os.getenv("KAFKA_BROKERCONNECT", "kafka:9092")


def push_suspicious_transaction_count_to_pushgateway (batch_id, count):
    print(f"Batch {batch_id}: count = {count}")

    registry = CollectorRegistry()
    gauge_count = Gauge('suspicious_transaction_count', 'Số lượng giao dịch bị nghi ngờ trong batch', registry=registry)
    gauge_count.set(count)
    push_to_gateway(PUSHGATEWAY_URL, job='suspicious_transaction_job', registry=registry)

    print(f"Đã đẩy metric của batch {batch_id} lên Pushgateway ({PUSHGATEWAY_URL}).")


def process_batch(batch_df, batch_id): 
    try: 
        suspicious_transaction_count = 0

        if batch_df.rdd.isEmpty():
            push_suspicious_transaction_count_to_pushgateway(batch_id, suspicious_transaction_count)
            return

        #processing
        suspicious_df = batch_df.filter(
            (col("amount") > 1000000000) |
            ((col("amount") > 500000000) & (hour(col("timestamp")) >= 1) & (hour(col("timestamp")) < 6))
        )

        suspicious_df.coalesce(1).write \
            .format("org.apache.spark.sql.cassandra") \
            .option("keyspace", "money_keyspace") \
            .option("table", "transactions") \
            .mode("append") \
            .save()

        agg_df = suspicious_df.agg(
            count("*").alias("suspicious_transaction_count")
        )
        result = agg_df.first()
        suspicious_transaction_count = result["suspicious_transaction_count"]

        push_suspicious_transaction_count_to_pushgateway(batch_id, suspicious_transaction_count)

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

    # spark = SparkSession.builder.appName("TransactionStreaming").getOrCreate()
    spark = SparkSession.builder \
        .appName("TransactionStreaming") \
        .config("spark.cassandra.connection.host", "cassandra") \
        .config("spark.cassandra.connection.port", "9042") \
        .config("spark.cassandra.auth.username", "cassandra") \
        .config("spark.cassandra.auth.password", "thinh3010") \
        .config("spark.cassandra.connection.keepAliveMS", "600000") \
        .getOrCreate()
    
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

    df_json = df_json.repartition(3)

    query = df_json.writeStream \
            .foreachBatch(process_batch) \
            .outputMode("append") \
            .start()
            

    query.awaitTermination()


if __name__ == "__main__":
    main()
