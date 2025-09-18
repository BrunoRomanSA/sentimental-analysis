FROM public.ecr.aws/lambda/python:3.12

# Instala build tools
RUN yum install -y gcc gcc-c++ make && yum clean all

# Copia os arquivos
COPY app.py requirements.txt ./
COPY .env .env

# Instala dependências
RUN pip install --no-cache-dir -r requirements.txt

# Define o handler
CMD ["app.lambda_handler"]
