import os
import json
import boto3
import mlflow
import logging
from botocore.exceptions import ClientError

def get_ssm_parameter(parameter_name: str, region_name: str = "us-east-1") -> str:
    """
    Busca o valor de um parâmetro no AWS Systems Manager (SSM) Parameter Store.

    Args:
        parameter_name (str): O nome do parâmetro a ser buscado (ex: /model/register/url).
        region_name (str): A região da AWS onde o parâmetro está localizado. 
                             O padrão é 'us-east-1'.

    Returns:
        str: O valor do parâmetro se encontrado, caso contrário, None.
    """
    try:
        # Cria um cliente SSM
        # Se as credenciais não forem passadas, o Boto3 tentará encontrá-las
        # automaticamente (variáveis de ambiente, arquivo de credenciais, perfil IAM da instância).
        ssm_client = boto3.client('ssm', region_name=region_name)

        # Busca o parâmetro
        # WithDecryption=True é necessário para parâmetros do tipo SecureString
        response = ssm_client.get_parameter(
            Name=parameter_name,
            WithDecryption=True
        )

        # Extrai e retorna o valor do parâmetro da resposta
        return response['Parameter']['Value']

    except ClientError as e:
        # Trata o erro específico de parâmetro não encontrado
        if e.response['Error']['Code'] == 'ParameterNotFound':
            print(f"Erro: O parâmetro '{parameter_name}' não foi encontrado na região '{region_name}'.")
        else:
            # Trata outros erros possíveis da API
            print(f"Ocorreu um erro inesperado ao acessar a AWS: {e}")
        return None
    except Exception as e:
        print(f"Ocorreu um erro no script: {e}")
        return None
# Configurar o logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)  

logger.info(f'MLflow Tracking URI: {os.getenv("MLFLOW_TRACKING_URI")}')
mlflow.set_tracking_uri(get_ssm_parameter(os.getenv("MLFLOW_TRACKING_URI")))

# Modelo do MLflow Registry
model_uri = "models:/IMDBSentimentModel@prod"
logger.info(f'Carregr modelo: {get_ssm_parameter(os.getenv("MLFLOW_TRACKING_URI"))}')
model = mlflow.pyfunc.load_model(model_uri)

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("output_modelo_imdb")

import hashlib

def map_texts_to_predictions(texts, predictions):
    """
    Recebe duas listas:
      texts = ["msg1", "msg2", ...]
      predictions = [1, 0, ...]
    Retorna um dicionário:
      {hash(msg1): 1, hash(msg2): 0, ...}
    """
    if len(texts) != len(predictions):
        raise ValueError("As listas devem ter o mesmo tamanho.")

    result = {}
    for text, pred in zip(texts, predictions):
        # Gera hash SHA256 para garantir consistência
        text_hash = hashlib.sha256(text.encode("utf-8")).hexdigest()
        result[text_hash] = pred
        response = save_prediction(text, pred)
        logger.info(f"Resultado salvo no dynamoDB {response}")
    return result

def save_prediction(review_text: str, prediction: int):
    """
    Salva no DynamoDB:
      - index: hash SHA256 do review
      - review: texto original
      - prediction_sentimental: 0 ou 1
    """
    # Gera hash único do review
    review_hash = hashlib.sha256(review_text.encode("utf-8")).hexdigest()

    response = table.put_item(
        Item={
            "index": review_hash,
            "review": review_text,
            "prediction_sentimental": prediction
        }
    )
    return response

def lambda_handler(event, context):
    """
    Espera evento JSON:
    {"reviews": ["texto1", "texto2", ...]}
    """
    # Log de entrada do evento
    logger.info(f"Recebido evento: {json.dumps(event)}")
    content = json.loads(event["body"])
    logger.info(f"Extraido conteudo do evento: {content} e tido do conteudo {type(content)}")
    reviews = content.get("reviews", [])
    if not reviews:
        return {
            "statusCode": 400,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "OPTIONS,POST",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            "body": json.dumps({"error": "Nenhuma review fornecida"})
        }

    preds = model.predict(reviews).tolist()
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps({"predictions": map_texts_to_predictions(reviews, preds)})
    }
