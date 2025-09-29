# =================================================================================
# AWS Launch Template
# Define um modelo de lançamento reutilizável para a instância do servidor MLflow.
# =================================================================================
resource "aws_launch_template" "mlflow_lt" {
  name_prefix   = "mlflow-server-template-"
  description   = "Launch template para o servidor MLflow"
  image_id      = "ami-06b21ccaeff8cd686"
  instance_type = "t2.micro"
  key_name      = "mlflow-credential"

  # Associa o Security Group especificado.
  vpc_security_group_ids = ["sg-081c04d079f62fec0"]

  # Configurações do volume de armazenamento (EBS).
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 32
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
      encrypted             = false
    }
  }

  # Associa o perfil IAM à instância para permissões (ex: acesso ao S3).
  iam_instance_profile {
    arn = "arn:aws:iam::503561450616:instance-profile/Ec2AccessS3"
  }

  # Script de User Data para configurar a instância na inicialização.
  # O script é codificado em base64, conforme exigido pela AWS.
  user_data = base64encode(<<-EOF
#!/bin/bash
# Redireciona toda a saída para um arquivo de log para depuração.
exec > >(tee /home/ec2-user/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "########## ATUALIZANDO PACOTES DO SISTEMA ##########"
sudo yum update -y

echo "########## INSTALANDO PYTHON 3 E PIP ##########"
sudo yum install -y python3 python3-pip

echo "########## VERIFICANDO VERSÃO DO PIP ##########"
pip3 --version

echo "########## REMOVENDO PACOTE 'requests' DO YUM PARA EVITAR CONFLITOS ##########"
sudo yum -y remove python3-requests

echo "########## CONFIGURANDO AMBIENTE VIRTUAL PYTHON ##########"
cd /home/ec2-user
python3 -m venv venv
source venv/bin/activate

echo "########## INSTALANDO DEPENDÊNCIAS PYTHON ##########"
pip3 install python-dateutil==2.8.2
pip3 install mlflow

echo "########## CRIANDO DIRETÓRIO PARA O BANCO DE DADOS DO MLFLOW ##########"
mkdir /home/ec2-user/mlflow

echo "########## INICIANDO O SERVIDOR MLFLOW ##########"
# O servidor usará um banco de dados SQLite local e armazenará artefatos no S3.
mlflow server \
    --backend-store-uri sqlite:////home/ec2-user/mlflow/mlflow.db \
    --default-artifact-root s3://mybucket-brunoroman/modelo/ \
    --host 0.0.0.0 \
    --port 5000 &
EOF
  )

  tags = {
    Name    = "mlflow-launch-template"
    Project = "MLOps"
  }
}

# =================================================================================
# AWS EC2 Instance
# Provisiona a instância EC2 usando o Launch Template definido acima.
# =================================================================================
resource "aws_instance" "mlflow_server" {
  launch_template {
    id      = aws_launch_template.mlflow_lt.id
    version = "$Latest" # Sempre usa a versão mais recente do template.
  }

  tags = {
    Name    = "mlflow-server-instance"
    Project = "MLOps"
  }
}

# =================================================================================
# AWS SSM Parameter Store
# Cria um parâmetro para armazenar a URL do servidor MLflow.
# =================================================================================
resource "aws_ssm_parameter" "model_register_url" {
  name  = "/model/register/url"
  type  = "String"
  value = "http://${aws_instance.mlflow_server.public_ip}:5000"
  
  description = "URL do servidor MLflow para registro de modelos."

  tags = {
    Name    = "mlflow-model-register-url"
    Project = "MLOps"
  }
}