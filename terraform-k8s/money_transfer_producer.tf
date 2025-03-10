resource "kubernetes_deployment" "money_transfer_producer" {
  metadata {
    name = "money-transfer-producer"
    namespace = "${var.streaming_pipeline_namespace}"
    labels = {
        app = "money-transfer-producer"
    }  
  }

  depends_on = [ 
    kubernetes_service.fake_transfer_money_api,
    kubernetes_job.create_kafka_topic
  ]

  spec {
    replicas = 1

    selector {
        match_labels = {
            app = "money-transfer-producer" 
        }
    }

    template {
      metadata {
        labels = {
           app = "money-transfer-producer"
        }
      }

      spec {
        container {
          name = "money-transfer-producer"
          image = "grunklestan/money_transfer_producer:latest"

          env {
            name = "KAFKA_BROKERCONNECT"
            value = "kafka:9092"
          }

          env {
            name = "SSE_API_URL"
            value = "http://fake-transfer-money-api:5000/transfer_data"
          }
        }
      }
    }
  }
}