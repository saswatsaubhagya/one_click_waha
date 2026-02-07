#!/bin/bash

set -e

echo "=========================================="
echo " WAHA Full Production Installer"
echo "=========================================="

#############################################
# 0️⃣ Ask for Domain
#############################################

read -p "Enter your primary domain (example.com): " PRIMARY_DOMAIN

if [ -z "$PRIMARY_DOMAIN" ]; then
    echo "Domain is required!"
    exit 1
fi

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
    echo "Docker already installed."
fi

#############################################
# 2️⃣ Setup WAHA Directory
#############################################

WAHA_DIR="/opt/waha"
mkdir -p $WAHA_DIR
cd $WAHA_DIR

#############################################
# 3️⃣ Generate Secure Credentials
#############################################

WAHA_API_KEY=$(openssl rand -hex 32)
WAHA_DASHBOARD_USERNAME="admin"
WAHA_DASHBOARD_PASSWORD=$(openssl rand -hex 32)
WHATSAPP_SWAGGER_USERNAME="admin"
WHATSAPP_SWAGGER_PASSWORD=$(openssl rand -hex 32)

#############################################
# 4️⃣ Create .env File
#############################################

cat <<EOF > .env
# ====================
# ===== SECURITY =====
# ====================
WAHA_API_KEY=${WAHA_API_KEY}
WAHA_DASHBOARD_USERNAME=${WAHA_DASHBOARD_USERNAME}
WAHA_DASHBOARD_PASSWORD=${WAHA_DASHBOARD_PASSWORD}
WHATSAPP_SWAGGER_USERNAME=${WHATSAPP_SWAGGER_USERNAME}
WHATSAPP_SWAGGER_PASSWORD=${WHATSAPP_SWAGGER_PASSWORD}

WAHA_DASHBOARD_ENABLED=True
WHATSAPP_SWAGGER_ENABLED=True

# ==================
# ===== COMMON =====
# ==================
WHATSAPP_DEFAULT_ENGINE=WEBJS
WAHA_BASE_URL=https://${PRIMARY_DOMAIN}
WAHA_PUBLIC_URL=https://${PRIMARY_DOMAIN}

# ===================
# ===== LOGGING =====
# ===================
WAHA_LOG_FORMAT=JSON
WAHA_LOG_LEVEL=info
WAHA_PRINT_QR=False

# =========================
# ===== MEDIA STORAGE =====
# =========================
WAHA_MEDIA_STORAGE=LOCAL
WHATSAPP_FILES_LIFETIME=0
WHATSAPP_FILES_FOLDER=/app/.media
EOF

echo ".env file created."

#############################################
# 5️⃣ Create docker-compose.yml
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
      - ./media:/app/.media
EOF

#############################################
# 6️⃣ Start WAHA
#############################################

docker compose up -d

sleep 5

#############################################
# 7️⃣ Display Credentials
#############################################

echo ""
echo "=========================================="
echo " WAHA Installed Successfully 🎉"
echo "=========================================="
echo "Domain: https://${PRIMARY_DOMAIN}"
echo "Local URL: http://SERVER_IP:3000"
echo ""
echo "WAHA_API_KEY:"
echo "${WAHA_API_KEY}"
echo ""
echo "Dashboard Login:"
echo "Username: ${WAHA_DASHBOARD_USERNAME}"
echo "Password: ${WAHA_DASHBOARD_PASSWORD}"
echo ""
echo "Swagger Login:"
echo "Username: ${WHATSAPP_SWAGGER_USERNAME}"
echo "Password: ${WHATSAPP_SWAGGER_PASSWORD}"
echo ""
echo "WAHA Directory: ${WAHA_DIR}"
echo "=========================================="
