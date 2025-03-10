terraform {
  required_providers {
    kubernetes = {
        source = "hashicorp/kubernetes"
        version = "2.35.1"
    }
    helm = {
        source = "hashicorp/helm"
        version = "2.17.0"
    }
    kubectl = {
        source = "gavinbunney/kubectl"
        version = "1.14.0"
    }
    kafka = {
      source = "Mongey/kafka"
      version = "0.8.3"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.kube_config)
  config_context = "minikube"
}


provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kube_config)
  }
}


#sử dụng để triển khai SparkApplication đúng cách
provider "kubectl" {}


provider "kafka" {
  # bootstrap_servers = ["kafka.streaming-pipeline.svc.cluster.local:9092"]
  bootstrap_servers = ["192.168.49.2:31004"]
}