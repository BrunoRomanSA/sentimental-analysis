variable "region" {
  default = "us-east-1"
}

variable "mlflow_tracking_uri" {
  description = "URI do MLflow tracking"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN da role da Lambda com permissões básicas"
  type        = string
}
