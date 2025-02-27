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
            replicaCount: 3
            automountServiceAccountToken: true

        externalAccess:
            enabled: true
            controller:
                service:
                    type: NodePort
                    ports:
                        external: 9094
            autoDiscovery:
                enabled: true

        serviceAccount:
            create: true

        rbac:
            create: true

        listeners:
            client:
                protocol: PLAINTEXT
            controller:
                protocol: PLAINTEXT

        broker:
            automountServiceAccountToken: true

        topic:
            autoCreate: true
        EOF
    ]
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
        helm_release.kafka
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