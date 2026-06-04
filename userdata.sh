#!/bin/bash
# ============================================
# USER DATA SCRIPT - Infraestructura como Código
# Aprovisionamiento automático de EC2 Ubuntu
# Despliegue de Laravel + Docker + LocalStack
# ============================================

set -e
LOG="/var/log/userdata.log"
echo "Iniciando aprovisionamiento: $(date)" >> $LOG

# 1. Actualizar sistema
apt-get update -y >> $LOG 2>&1
apt-get upgrade -y >> $LOG 2>&1

# 2. Instalar dependencias base
apt-get install -y git curl unzip >> $LOG 2>&1

# 3. Instalar Docker
curl -fsSL https://get.docker.com | bash >> $LOG 2>&1
usermod -aG docker ubuntu

# 4. Instalar Docker Compose plugin
apt-get install -y docker-compose-plugin >> $LOG 2>&1

# 5. Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install >> $LOG 2>&1

# 6. Clonar repositorio desde GitHub
cd /home/ubuntu
git clone https://github.com/23Vvrangler/laravel-cloud-devops.git >> $LOG 2>&1
cd laravel-cloud-devops

# 7. Configurar variables de entorno
cp .env.example .env

# 8. Levantar contenedores
docker compose -f compose.dev.yaml up -d --build >> $LOG 2>&1

# 9. Esperar que los servicios estén listos
sleep 30

# 10. Configurar Laravel
docker compose -f compose.dev.yaml exec -T php-fpm php artisan key:generate
docker compose -f compose.dev.yaml exec -T php-fpm php artisan migrate --force

# 11. Crear recursos en LocalStack
aws --endpoint-url=http://localhost:4566 s3 mb s3://laravel-bucket
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name laravel-queue

echo "Aprovisionamiento completado: $(date)" >> $LOG
