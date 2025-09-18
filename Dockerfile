FROM public.ecr.aws/lambda/python:3.12

# Atualiza pacotes e instala build-essential
RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copia os arquivos
COPY app.py requirements.txt ./
COPY .env .env


# Atualiza pip, setuptools e wheel
RUN python -m pip install --upgrade pip setuptools wheel

# Instala dependências
RUN pip install --no-cache-dir -r requirements.txt

# Define o handler
CMD ["app.lambda_handler"]
