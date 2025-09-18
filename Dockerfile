FROM public.ecr.aws/lambda/python:3.12

# Copia os arquivos
COPY app.py requirements.txt ./
COPY .env .env


# Atualiza pip, setuptools e wheel
RUN python -m pip install --upgrade pip setuptools wheel

# Instala dependências
RUN pip install --no-cache-dir -r requirements.txt

# Define o handler
CMD ["app.lambda_handler"]
