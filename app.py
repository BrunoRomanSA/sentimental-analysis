import os
import json
import mlflow
from dotenv import load_dotenv

# Carrega variáveis do .env (MLFLOW_TRACKING_URI)
load_dotenv()

mlflow.set_tracking_uri(os.getenv("MLFLOW_TRACKING_URI"))

# Modelo do MLflow Registry
model_uri = "models:/IMDBSentimentModel@prod"
model = mlflow.pyfunc.load_model(model_uri)

def lambda_handler(event, context):
    """
    Espera evento JSON:
    {"reviews": ["texto1", "texto2", ...]}
    """
    reviews = event.get("reviews", [])
    if not reviews:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Nenhuma review fornecida"})
        }

    preds = model.predict(reviews).tolist()
    return {
        "statusCode": 200,
        "body": json.dumps({"predictions": preds})
    }
