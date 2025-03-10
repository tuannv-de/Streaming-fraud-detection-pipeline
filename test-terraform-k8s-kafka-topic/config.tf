resource "kubernetes_namespace" "pipeline_namespace" {
  metadata {
    name = "${var.streaming_pipeline_namespace}"
  }
}


resource "kubernetes_namespace" "spark_namespace" {
  metadata {
    name = "${var.spark_namespace}"
  }
}


//tạo namespace ở đây

# resource "kubernetes_secret" "credentials" {
#     metadata {
#       name = "credentials"
#       namespace = "${var.namespace}"
#     }

#     depends_on = [ kubernetes_namespace.pipeline_namespace ]

#     data = {
#       "credentials.cfg" = "${file("../secrets/credentials.cfg")}"
#     }
# }


resource "kubernetes_network_policy" "pipeline_network" {
  metadata {
    name = "pipeline-network"
    namespace = "${var.streaming_pipeline_namespace}"
  }

  depends_on = [ kubernetes_namespace.pipeline_namespace ]

  spec {
    pod_selector {
      match_labels = {
        "k8s.network/pipeline-network" = "true"
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "k8s.network/pipeline-network" = "true"
          }
        }
      }
    }
  }
}