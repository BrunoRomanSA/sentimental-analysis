provider "aws" {
  region = var.region
}

# -----------------------------
# IAM Role para Lambda
# -----------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "imdb-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
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
resource "aws_iam_role_policy_attachment" "lambda_ecr_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach policy mínima para logs
resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# 👇 nova policy inline com sts:GetServiceBearerToken
resource "aws_iam_role_policy" "lambda_sts_token" {
  name = "lambda-sts-token"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:GetServiceBearerToken"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "sts:AWSServiceName" = "ecr.amazonaws.com"
          }
        }
      }
    ]
  })
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
      MLFLOW_TRACKING_URI = var.mlflow_tracking_uri,
      MLFLOW_EXPERIMENT_NAME = var.mlflow_experiment_name
    }
  }

  # Role da Lambda
  role = aws_iam_role.lambda_exec_role.arn

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_ecr_policy
  ]
}

