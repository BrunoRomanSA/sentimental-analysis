provider "aws" {
  region = var.region
}

# ECR Repository
# resource "aws_ecr_repository" "lambda_repo" {
#   name = "imdb-lambda-repo"
#   lifecycle {
#     prevent_destroy = true
#     ignore_changes  = [repository_url] # opcional
#   }
# }

# -----------------------------
# IAM Role para Lambda
# -----------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "imdb-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}



resource "aws_iam_role_policy" "lambda_ecr_policy" {
  name = "lambda-ecr-access"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy mínima para logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach policy mínima para logs
resource "aws_iam_role_policy_attachment" "lambda_ecr_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_ecr_access.arn
}

# Lambda Function usando container image do ECR
resource "aws_lambda_function" "imdb_lambda" {
  function_name = "imdb-sentiment-lambda"
  package_type  = "Image"
  image_uri     = "503561450616.dkr.ecr.us-east-1.amazonaws.com/imdb-lambda-repo:latest"

  timeout     = 30
  memory_size = 1024

  # Variáveis de ambiente
  environment {
    variables = {
      MLFLOW_TRACKING_URI = var.mlflow_tracking_uri
    }
  }

  # Role da Lambda
  role = aws_iam_role.lambda_exec_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

