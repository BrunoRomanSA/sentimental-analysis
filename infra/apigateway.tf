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

# --- 3. Define o Método POST para a rota /reviews ---
resource "aws_api_gateway_method" "reviews_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  resource_id   = aws_api_gateway_resource.reviews_resource.id
  http_method   = "POST"
  authorization = "NONE" # Nenhuma autorização, já que a API será pública
}

# --- 4. Define a Integração entre o Método POST e a Função Lambda ---
# Esta parte conecta a chamada à API com a execução da Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.sentiment_api.id
  resource_id             = aws_api_gateway_resource.reviews_resource.id
  http_method             = aws_api_gateway_method.reviews_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY" # Integração direta com a Lambda (tipo proxy)
  uri                     = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:503561450616:function:imdb-sentiment-lambda/invocations"
}

# --- 5. Habilita o CORS (Cross-Origin Resource Sharing) ---
# Isso permite que sua aplicação web (front-end) faça requisições para a API
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
  type        = "MOCK" # Uma integração MOCK é usada para o CORS
}

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

# --- 6. Define o "Deploy" e o "Stage" da API ---
# O API Gateway precisa ser "publicado" para ser acessível
resource "aws_api_gateway_deployment" "reviews_deployment" {
  rest_api_id = aws_api_gateway_rest_api.sentiment_api.id

  # Depende da criação do método POST, da integração e das configurações de CORS
  depends_on = [
    aws_api_gateway_method.reviews_post_method,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_method_response.reviews_post_response,
    aws_api_gateway_integration_response.reviews_post_integration_response
  ]

  # Adiciona um "gatilho" para forçar uma nova implantação quando a configuração muda
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.reviews_post_method.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_method_response.reviews_post_response.id,
      aws_api_gateway_integration_response.reviews_post_integration_response.id
    ]))
  }
}


# --- 6.1. Define o Stage da API ---
resource "aws_api_gateway_stage" "reviews_stage" {
  deployment_id = aws_api_gateway_deployment.reviews_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.sentiment_api.id
  stage_name    = "dev"
}

# --- 7. Adiciona permissão para o API Gateway invocar a Lambda ---
# A API Gateway precisa de permissão explícita para invocar a Lambda
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "imdb-sentiment-lambda"
  principal     = "apigateway.amazonaws.com"

  # Usa o ARN da API Gateway para garantir que a permissão é para a sua API específica
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.sentiment_api.id}/*/*"
}