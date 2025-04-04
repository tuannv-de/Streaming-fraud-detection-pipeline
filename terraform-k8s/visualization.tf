resource "helm_release" "prometheus" {
  name = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "prometheus"
  version = "27.5.1"
  namespace = "${var.streaming_pipeline_namespace}"

  depends_on = [ kubernetes_namespace.pipeline_namespace, ]

  values = [
    file("values_prometheus.yaml")
  ]

}


resource "helm_release" "grafana" {
  name = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart = "grafana"
  version = "8.10.3"
  namespace = "${var.streaming_pipeline_namespace}"

  depends_on = [ kubernetes_deployment.money_transfer_producer ]

  values = [
    file("values_grafana.yaml")
  ]
}


resource "kubernetes_config_map" "suspicious_transaction_dashboard" {
  metadata {
    name = "suspicious-transaction-dashboard"
    namespace = "${var.streaming_pipeline_namespace}"
    labels = {
      grafana_dashboard = "1" 
    }
  }

  depends_on = [ kubernetes_namespace.pipeline_namespace ]

  data = {
    "suspicious-transaction-dashboard.json" = file("../grafana/dashboards/suspicious-transaction-dashboard.json")
  }
}