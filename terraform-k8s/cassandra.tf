resource "helm_release" "cassandra" {
  name = "cassandra"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart = "cassandra"
  version = "12.1.3"
  namespace = "${var.streaming_pipeline_namespace}"

  depends_on = [ kubernetes_secret.cassandra_key ]

  values = [<<EOF
metrics:
  enabled: true
  serviceMonitor:
    enabled: true

dbUser:
  forcePassword: true
  existingSecret: cassandra-key

EOF
  ]
}


resource "kubernetes_secret" "cassandra_key" {
  metadata {
    name = "cassandra-key"
    namespace = "${var.streaming_pipeline_namespace}"
  }

  depends_on = [ kubernetes_namespace.pipeline_namespace ]

  data = {
    cassandra-password = "thinh3010"
  }
}


resource "kubernetes_config_map" "cassandra_setup_cql" {
  metadata {
    name      = "cassandra-setup-cql"
    namespace = "${var.streaming_pipeline_namespace}"
  }

  depends_on = [ kubernetes_namespace.pipeline_namespace ]

  data = {
    "cassandra-setup.cql" = file("../cassandra/cassandra-setup.cql")
  }
}



resource "kubernetes_job" "cassandra_init" {
  metadata {
    name = "cassandra-init"
    namespace = "${var.streaming_pipeline_namespace}"
  }

  depends_on = [ helm_release.cassandra ]

  spec {
    backoff_limit = 1
    template {
      metadata {
        name = "cassandra-init"
      }

      spec {
        restart_policy = "Never"
        container {
          name = "cassandra-client"
          image = "docker.io/bitnami/cassandra:5.0.2-debian-12-r4"

          volume_mount {
            name       = "cql-scripts"
            mount_path = "/scripts"
          }

          command = [ 
            "bash",
            "-c",
            "sleep 30; cqlsh -u cassandra -p thinh3010 cassandra-0.cassandra-headless.streaming-pipeline.svc.cluster.local -f /scripts/cassandra-setup.cql "
           ]
        }

        volume {
          name = "cql-scripts"
          config_map {
            name = kubernetes_config_map.cassandra_setup_cql.metadata[0].name
          }
        }
      }
    }
  }
}