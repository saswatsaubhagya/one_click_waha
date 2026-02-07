#!/bin/bash

set -e

echo "=========================================="
echo " WAHA Auto Installer (Official ENV)"
echo "=========================================="

#############################################
# 1️⃣ Install Docker if not present
#############################################

if ! command -v docker &> /dev/null
then
    echo "Docker not found. Installing Docker..."

    apt update
    apt install -y ca-certificates curl gnupg lsb-release

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

#############################################
# 2️⃣ Check Docker Compose
#############################################

if ! docker compose version &> /dev/null
then
    apt install -y docker-compose-plugin
fi

#############################################
# 3️⃣ Setup WAHA Directory
#############################################

WAHA_DIR="/opt/waha"
mkdir -p $WAHA_DIR
cd $WAHA_DIR

#############################################
# 4️⃣ Generate Secure Credentials
#############################################

WAHA_API_KEY=$(openssl rand -hex 32)
WAHA_DASHBOARD_PASSWORD=$(openssl rand -base64 16)
WHATSAPP_SWAGGER_PASSWORD=$(openssl rand -base64 16)

#############################################
# 5️⃣ Create .env file (Official Variables)
#############################################

cat <<EOF > .env
WAHA_API_KEY=${WAHA_API_KEY}
WAHA_DASHBOARD_PASSWORD=${WAHA_DASHBOARD_PASSWORD}
WHATSAPP_SWAGGER_PASSWORD=${WHATSAPP_SWAGGER_PASSWORD}
EOF

echo ".env file created."

#############################################
# 6️⃣ Create docker-compose.yml
#############################################

cat <<EOF > docker-compose.yml
version: '3.8'

services:
  waha:
    image: devlikeapro/waha:latest
    container_name: waha
    restart: always
    env_file:
      - .env
    ports:
      - "3000:3000"
    volumes:
      - ./sessions:/app/sessions
EOF

#############################################
# 7️⃣ Start WAHA
#############################################

docker compose up -d

sleep 5

#############################################
# 8️⃣ Display Credentials
#############################################

echo "=========================================="
echo " WAHA Installed Successfully 🎉"
echo "=========================================="
echo "URL: http://localhost:3000"
echo ""
echo "WAHA_API_KEY:"
echo "${WAHA_API_KEY}"
echo ""
echo "WAHA_DASHBOARD_PASSWORD:"
echo "${WAHA_DASHBOARD_PASSWORD}"
echo ""
echo "WHATSAPP_SWAGGER_PASSWORD:"
echo "${WHATSAPP_SWAGGER_PASSWORD}"
echo ""
echo "WAHA Directory: ${WAHA_DIR}"
echo "=========================================="
