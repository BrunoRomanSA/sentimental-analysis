FROM public.ecr.aws/lambda/python:3.11

# Copia os arquivos
COPY app.py requirements.txt ./
COPY .env .env

# Instala dependências
RUN pip install --no-cache-dir -r requirements.txt

# Define o handler
CMD ["app.lambda_handler"]
