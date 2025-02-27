variable "kube_config" {
  type = string
  default = "~/.kube/config"
}

variable "streaming_pipeline_namespace" {
  type = string
  default = "streaming-pipeline"
}


variable "spark_namespace" {
  type = string
  default = "spark-operator"
}