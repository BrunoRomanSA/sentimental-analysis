import os
import json
import boto3
import mlflow
import logging

# Configurar o logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)  

logger.info(f'MLflow Tracking URI: {os.getenv("MLFLOW_TRACKING_URI")}')
mlflow.set_tracking_uri(os.getenv("MLFLOW_TRACKING_URI"))

# Modelo do MLflow Registry
model_uri = "models:/IMDBSentimentModel@prod"
logger.info(f'Carregr modelo: {os.getenv("MLFLOW_TRACKING_URI")}')
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
