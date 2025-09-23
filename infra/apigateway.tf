# --- 1. Cria o API Gateway (REST API) ---
resource "aws_api_gateway_rest_api" "sentiment_api" {
  name        = "SentimentApiGateway"
  description = "API Gateway para a função Lambda de análise de sentimento IMDB."
}

# --- 2. Cria o Recurso /reviews (a rota) ---
resource "aws_api_gateway_resource" "reviews_resource" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  parent_id   = aws_api_gateway_rest_api.sentiment_api.root_resource_id
  path_part   = "reviews"
}

# --- 2b. Cria o Recurso /evaluate (a rota) ---
resource "aws_api_gateway_resource" "evaluate_resource" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  parent_id   = aws_api_gateway_rest_api.sentiment_api.root_resource_id
  path_part   = "evaluate"
}

# --- 3. Define o Método POST para a rota /reviews ---
resource "aws_api_gateway_method" "reviews_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  resource_id   = aws_api_gateway_resource.reviews_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# --- 3b. Define o Método POST para a rota /evaluate ---
resource "aws_api_gateway_method" "evaluate_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  resource_id   = aws_api_gateway_resource.evaluate_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# --- 4. Define a Integração entre o Método POST e a Função Lambda ---
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.sentiment_api.id
  resource_id             = aws_api_gateway_resource.reviews_resource.id
  http_method             = aws_api_gateway_method.reviews_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:503561450616:function:imdb-sentiment-lambda/invocations"
}

# --- 4b. Integração entre POST /evaluate e Lambda evaluate ---
resource "aws_api_gateway_integration" "evaluate_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.sentiment_api.id
  resource_id             = aws_api_gateway_resource.evaluate_resource.id
  http_method             = aws_api_gateway_method.evaluate_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:503561450616:function:evaluate-sentiment-lambda/invocations"
}

# --- 5. Habilita o CORS ---
# OPTIONS method
resource "aws_api_gateway_method" "reviews_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  resource_id   = aws_api_gateway_resource.reviews_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "reviews_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.reviews_resource.id
  http_method = aws_api_gateway_method.reviews_options_method.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\":200}"
  }
}

# Resposta do POST
resource "aws_api_gateway_method_response" "reviews_post_response" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.reviews_resource.id
  http_method = aws_api_gateway_method.reviews_post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "reviews_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.reviews_resource.id
  http_method = aws_api_gateway_method.reviews_post_method.http_method
  status_code = aws_api_gateway_method_response.reviews_post_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Resposta do OPTIONS (CORS)
resource "aws_api_gateway_method_response" "reviews_options_response" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.reviews_resource.id
  http_method = aws_api_gateway_method.reviews_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "reviews_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.reviews_resource.id
  http_method = aws_api_gateway_method.reviews_options_method.http_method
  status_code = aws_api_gateway_method_response.reviews_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }
}

# --- 5b. Habilita o CORS para /evaluate ---
# OPTIONS method
resource "aws_api_gateway_method" "evaluate_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  resource_id   = aws_api_gateway_resource.evaluate_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "evaluate_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.evaluate_resource.id
  http_method = aws_api_gateway_method.evaluate_options_method.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\":200}"
  }
}

# Resposta do POST /evaluate
resource "aws_api_gateway_method_response" "evaluate_post_response" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.evaluate_resource.id
  http_method = aws_api_gateway_method.evaluate_post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "evaluate_post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.evaluate_resource.id
  http_method = aws_api_gateway_method.evaluate_post_method.http_method
  status_code = aws_api_gateway_method_response.evaluate_post_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Resposta do OPTIONS (CORS) /evaluate
resource "aws_api_gateway_method_response" "evaluate_options_response" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.evaluate_resource.id
  http_method = aws_api_gateway_method.evaluate_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "evaluate_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id
  resource_id = aws_api_gateway_resource.evaluate_resource.id
  http_method = aws_api_gateway_method.evaluate_options_method.http_method
  status_code = aws_api_gateway_method_response.evaluate_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = ""
  }
}


# --- 6. Define o "Deploy" e o "Stage" da API ---
resource "aws_api_gateway_deployment" "reviews_deployment" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id

  depends_on = [
    aws_api_gateway_method.reviews_post_method,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method_response.reviews_post_response,
    aws_api_gateway_integration_response.reviews_post_integration_response,
    aws_api_gateway_method_response.reviews_options_response,
    aws_api_gateway_integration_response.reviews_options_integration_response
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.reviews_post_method.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_method_response.reviews_post_response.id,
      aws_api_gateway_integration_response.reviews_post_integration_response.id,
      aws_api_gateway_method_response.reviews_options_response.id,
      aws_api_gateway_integration_response.reviews_options_integration_response.id
    ]))
  }
}

# --- 6.1. Define o Stage da API (com logging habilitado) ---
resource "aws_api_gateway_stage" "reviews_stage" {
  deployment_id = aws_api_gateway_deployment.reviews_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  stage_name    = "dev"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  xray_tracing_enabled = true
}

# --- 7. Adiciona permissão para o API Gateway invocar a Lambda ---
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "imdb-sentiment-lambda"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.sentiment_api.id}/*/*"
}

# --- 7b. Permissão para API Gateway invocar a Lambda evaluate ---
resource "aws_lambda_permission" "apigw_lambda_permission_evaluate" {
  statement_id  = "AllowAPIGatewayInvokeEvaluate"
  action        = "lambda:InvokeFunction"
  function_name = "evaluate-sentiment-lambda"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.sentiment_api.id}/*/*"
}

# --- 8. Cria Role para o API Gateway gerar logs no CloudWatch ---
resource "aws_iam_role" "apigateway_role" {
  name = "apigateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigateway_logs" {
  role       = aws_iam_role.apigateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.apigateway_role.arn
}

# --- 9. Log Group para armazenar os logs do API Gateway ---
resource "aws_cloudwatch_log_group" "apigateway_logs" {
  name              = "/aws/apigateway/sentiment-api"
  retention_in_days = 3
}
