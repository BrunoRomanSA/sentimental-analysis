import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score, f1_score, classification_report
import mlflow
import mlflow.sklearn
import os
from dotenv import load_dotenv

# =========================
# CONFIGURAÇÃO DO MLFLOW
# =========================
load_dotenv()
mlflow.set_tracking_uri(os.getenv("MLFLOW_TRACKING_URI"))
mlflow.set_experiment("imdb_sentiment")

# =========================
# CARREGAR E TREINAR MODELO
# =========================
df = pd.read_csv("archive/IMDB Dataset.csv")
df['Category'] = df['sentiment'].apply(lambda x: 1 if x == 'positive' else 0)

X = df['review']
y = df['Category']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

pipeline = Pipeline([
    ('vectorizer', CountVectorizer(max_features=5000)),
    ('classifier', MultinomialNB())
])

# =========================
# EXECUÇÃO NO MLFLOW
# =========================
with mlflow.start_run(run_name="multinb_baseline") as run:
    pipeline.fit(X_train, y_train)
    
    y_pred = pipeline.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)

    print(classification_report(y_test, y_pred))

    mlflow.log_param("vectorizer_max_features", 5000)
    mlflow.log_param("classifier", "MultinomialNB")
    mlflow.log_metric("accuracy", acc)
    mlflow.log_metric("f1_score", f1)

    mlflow.sklearn.log_model(
        sk_model=pipeline,
        artifact_path="model",
        registered_model_name="IMDBSentimentModel"
    )

print("✅ Modelo salvo no MLflow remoto com sucesso!")
