resource "kubernetes_deployment" "fake_transfer_money_api" {
  metadata {
    name = "fake-transfer-money-api"
    namespace = "${var.streaming_pipeline_namespace}"
    labels = {
      app = "fake-transfer-money-api"
    }
  }

  depends_on = [ kubernetes_namespace.pipeline_namespace ]

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "fake-transfer-money-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "fake-transfer-money-api"
        }
      }

      spec {
        container {
          name = "fake-transfer-money-api"
          image = "grunklestan/fastapi_generate_data:latest"
          port {
            container_port = 5000
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "fake_transfer_money_api" {
  metadata {
    name = "fake-transfer-money-api"
    namespace = "${var.streaming_pipeline_namespace}"
    labels = {
      app = "fake-transfer-money-api"
    }
  }

  depends_on = [ kubernetes_deployment.fake_transfer_money_api ]

  spec {
    port {
      port = 5000
      target_port = 5000
      name = "fake-transfer-money-api"
      protocol = "TCP"
      node_port = 30080
    }

    selector = {
      app = "fake-transfer-money-api"
    }

    type = "NodePort"
  }
}