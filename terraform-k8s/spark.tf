resource "helm_release" "spark" {
  name = "spark-operator"
  repository = "https://kubeflow.github.io/spark-operator"
  chart = "spark-operator"
  version = "2.1.0"
  namespace = "${var.spark_namespace}"

  depends_on = [ kubernetes_cluster_role_binding.spark_role ]

  set {
    name = "spark.jobNamespaces"
    value = "{${var.streaming_pipeline_namespace}}"
  }

  set {
    name = "webhook.enable"
    value = true
  }

  set {
    name  = "webhook.port"
    value = "443"
  }
}


resource "kubernetes_service_account" "spark_service_account" {
  metadata {
    name = "spark"
    namespace = "${var.streaming_pipeline_namespace}"
  }

  depends_on = [ 
        kubernetes_namespace.pipeline_namespace,
        kubernetes_namespace.spark_namespace
    ]
}


resource "kubernetes_cluster_role_binding" "spark_role" {
  metadata {
    name = "spark-role"
  }

  depends_on = [ kubernetes_service_account.spark_service_account ]

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "edit"
  }

  subject {
    kind = "ServiceAccount"
    name = kubernetes_service_account.spark_service_account.metadata[0].name
    namespace = kubernetes_service_account.spark_service_account.metadata[0].namespace
  }
}