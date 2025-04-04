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


resource "kubernetes_manifest" "spark_application" {
  depends_on = [ 
    kubernetes_job.create_kafka_topic,
    helm_release.prometheus,
    helm_release.spark
  ]

  manifest = {
    "apiVersion" = "sparkoperator.k8s.io/v1beta2"
    "kind"       = "SparkApplication"
    "metadata" = {
      "name"      = "money-transfer-spark-streaming"
      "namespace" = "${var.streaming_pipeline_namespace}"
    }
    "spec" = {
      "type"               = "Python"
      "pythonVersion"      = "3"
      "mode"               = "cluster"
      "image"              = "grunklestan/money_transfer_spark_stream_processor:latest"
      "imagePullPolicy"    = "Always"
      "mainApplicationFile"= "local:///app/spark_stream_processor.py"
      "sparkVersion"       = "3.5.3"
      "sparkConf" = {
        "spark.jars.packages" = "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.3,com.datastax.spark:spark-cassandra-connector_2.12:3.5.1"
        "spark.jars.ivy"                   = "/tmp/.ivy"
        "spark.driver.extraJavaOptions"    = "-Divy.cache.dir=/tmp -Divy.home=/tmp"
        "spark.executor.extraJavaOptions"  = "-Divy.cache.dir=/tmp -Divy.home=/tmp"
        "spark.hadoop.security.authentication" = "simple"
      }

      "restartPolicy" = {
        "type" = "Never"
      }
      "driver" = {
        "labels" = {
          "version" = "3.5.3"
        }
        "serviceAccount" = "spark"
        "cores"          = 1
        "memory"         = "3g"
        "env" = [
          {
            "name"  = "KAFKA_BROKERCONNECT"
            "value" = "kafka:9092"
          },
          {
            "name"  = "PUSHGATEWAY_URL"
            "value" = "prometheus-prometheus-pushgateway:9091"
          }
        ]
      }
      "executor" = {
        "labels" = {
          "version" = "3.5.3"
        }
        "instances" = 1
        "cores"     = 2
        "memory"    = "2g"
        "env" = [
          {
            "name"  = "KAFKA_BROKERCONNECT"
            "value" = "kafka:9092"
          },
          {
            "name"  = "PUSHGATEWAY_URL"
            "value" = "prometheus-prometheus-pushgateway:9091"
          }
        ]
      }
    }
  }
}