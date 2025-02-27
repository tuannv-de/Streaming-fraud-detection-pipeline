resource "helm_release" "visual-data" {
  name = "visual-data"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"
  version = "69.2.0"
  namespace = "${var.streaming_pipeline_namespace}"

  depends_on = [ helm_release.cassandra ]

  values = [file("values.yaml")]
}