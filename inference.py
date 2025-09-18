import os
from dotenv import load_dotenv
import mlflow

# Carrega variáveis do .env (contendo MLFLOW_TRACKING_URI)
load_dotenv()

# Configura o tracking do MLflow
mlflow.set_tracking_uri(os.getenv("MLFLOW_TRACKING_URI"))

# Carrega o modelo pela referência do registry (nome + stage)
model_uri = "models:/IMDBSentimentModel@prod"
model = mlflow.pyfunc.load_model(model_uri)

# Exemplo de uso
reviews = [
    "This movie was fantastic, I loved it!",
    "Terrible plot and bad acting."
]

preds = model.predict(reviews)
print(preds)