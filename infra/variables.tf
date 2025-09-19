variable "region" {
  default = "us-east-1"
}

variable "mlflow_tracking_uri" {
  description = "URI do MLflow tracking"
  type        = string
}

