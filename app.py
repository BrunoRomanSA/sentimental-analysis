import os
import json
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
                "Access-Control-Allow-Methods": "POST,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            "body": json.dumps({"error": "Nenhuma review fornecida"})
        }

    preds = model.predict(reviews).tolist()
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        },
        "body": json.dumps({"predictions": preds})
    }
