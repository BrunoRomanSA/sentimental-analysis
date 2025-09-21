variable "region" {
  default = "us-east-1"
}

variable "mlflow_tracking_uri" {
  description = "URI do MLflow tracking"
  type        = string
}

variable "mlflow_experiment_name" {
  description = "URI do MLflow tracking"
  type        = string
}

variable "account_id" {
  description = "ID da conta AWS"
  # Substitua pelo ID da sua conta
  default     = "503561450616" 
}