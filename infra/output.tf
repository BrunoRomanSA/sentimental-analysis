output "lambda_function_name" {
  value = aws_lambda_function.imdb_lambda.function_name
}

# output "ecr_repo_url" {
#   value = aws_ecr_repository.lambda_repo.repository_url
# }


output "api_url" {
  description = "URL do API Gateway"
  value       = "${aws_api_gateway_stage.reviews_stage.invoke_url}/${aws_api_gateway_resource.reviews_resource.path_part}"
}


output "instance_public_ip" {
  description = "O IP público da instância EC2 do servidor MLflow."
  value       = aws_instance.mlflow_server.public_ip
}

output "ssm_parameter_name" {
  description = "O nome do parâmetro SSM criado."
  value       = aws_ssm_parameter.model_register_url.name
}
