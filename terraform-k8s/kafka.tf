resource "helm_release" "kafka" {
    name    = "kafka"
    repository = "oci://registry-1.docker.io/bitnamicharts"
    chart   = "kafka"
    version = "31.3.1"
    namespace  =  "${var.streaming_pipeline_namespace}"

    depends_on = [ 
        kubernetes_namespace.pipeline_namespace
    ]

    values = [
            <<-EOF
        controller:
            replicaCount: 1
            automountServiceAccountToken: true

        externalAccess:
            enabled: true
            controller:
                service:
                    type: NodePort
                    externalIPs:
                        - "192.168.49.2"
                    nodePorts:
                        - "31001"
            broker:
                service:
                    type: NodePort
                    externalIPs:
                        - "192.168.49.2"
                    nodePorts:
                        - "31004"



        serviceAccount:
            create: true

        rbac:
            create: true

        listeners:
            client:
                protocol: PLAINTEXT
            controller:
                protocol: PLAINTEXT
            external:
                protocol: PLAINTEXT
            advertisedListener:  "EXTERNAL://192.168.49.2:31004"

        broker:
            replicaCount: 1
            automountServiceAccountToken: true

        topic:
            autoCreate: true
        EOF
    ]
}


resource "kubernetes_job" "create_kafka_topic" {
  metadata {
    name = "create-kafka-topic-job"
  }

  depends_on = [ helm_release.kafka ]

  spec {
    template {
      metadata {
        labels = {
          app = "kafka-topic-creator"
        }
      }

      spec {
        # thực ra có thể kết nối dạng internal ip, nhưng ở đây để test external ip với mục đích mở rộng và phát triển
        container {
          name  = "kafka-client"
          image = "bitnami/kafka:latest" # Sử dụng image Kafka từ Bitnami
          command = [
            "/bin/sh",
            "-c",
            "kafka-topics.sh --create --topic money_transfer --bootstrap-server 192.168.49.2:31004 --partitions 3 --replication-factor 1"
          ]
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 2
  }
}


resource "kubernetes_deployment" "kafdrop" {
    metadata {
        name = "kafdrop"
        namespace  =  "${var.streaming_pipeline_namespace}"
        labels = {
            app = "kafdrop"
        }
    }

    depends_on = [ 
        kubernetes_job.create_kafka_topic
    ]

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = "kafdrop"
            }  
        }

        template {
            metadata {
                labels = {
                    app = "kafdrop"
                } 
            }

            spec {
                container {
                    name = "kafdrop"
                    image = "obsidiandynamics/kafdrop:latest"
                    port {
                        container_port = 9000
                    }
                    env {
                        name = "KAFKA_BROKERCONNECT"
                        value = "kafka:9092"
                    }
                }
            }
        }
    }  
}


resource "kubernetes_service" "kafdrop" {
    metadata {
        name = "kafdrop"
        namespace  =  "${var.streaming_pipeline_namespace}"
        labels = {
          name = "kafdrop"
        }
    }

    depends_on = [ 
        kubernetes_deployment.kafdrop
    ]

    spec {
      port {
        port = 9000
        target_port = 9000
        name = "kafdrop"
        protocol = "TCP"
        node_port = 30090
      }

      selector = {
        app = "kafdrop"
      }

      type = "NodePort"
    }
}


# kubectl port-forward service/kafdrop -n streaming-pipeline 9000:9000