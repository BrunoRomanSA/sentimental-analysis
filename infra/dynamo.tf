resource "aws_dynamodb_table" "output_modelo_imdb" {
  name           = "output_modelo_imdb"
  billing_mode   = "PAY_PER_REQUEST" # custo otimizado (on-demand)
  hash_key       = "index"

  attribute {
    name = "index"
    type = "S" # String (hash do review)
  }

  tags = {
    Environment = "dev"
    Project     = "imdb-sentiment"
  }
}
