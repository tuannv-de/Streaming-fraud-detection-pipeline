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

  depends_on = [ helm_release.prometheus ]

  values = [
    <<EOF
grafana.ini:
  dashboards:
    min_refresh_interval: 1s
EOF
  ]
}