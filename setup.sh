#!/bin/bash

# Visual Styling
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}==============================${NC}"
echo -e "${BLUE}   n8n Self Hosted Setup      ${NC}"
echo -e "${BLUE}==============================${NC}"

# --- PRE-FLIGHT CHECKS ---
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[Error] Docker is not installed.${NC}"
    exit 1
fi

if [ -f .env ]; then
    echo -e "${YELLOW}[Warning] .env file already exists.${NC}"
    read -p "Overwrite? (y/n): " overwrite
    if [[ $overwrite != "y" ]]; then exit 0; fi
fi

# --- 1. ENV SELECTION ---
echo -e "\n${GREEN}1. Infrastructure:${NC}"
echo "   [L] Local  (Mac/Windows/Linux - No SSL)"
echo "   [P] Prod   (VPS - SSL + S3 Backup Option)"
read -p "Select (L/P): " env_choice

# --- 2. CONFIGURATION ---
echo -e "\n${GREEN}2. Configuration:${NC}"

# Container Name
read -p "Container Name (default: n8n-main): " CONTAINER_NAME
CONTAINER_NAME=${CONTAINER_NAME:-n8n-main}

# DB Credentials
read -p "DB User (default: n8n): " POSTGRES_USER
POSTGRES_USER=${POSTGRES_USER:-n8n}

read -p "DB Password (leave empty to auto-generate): " POSTGRES_PASSWORD
if [ -z "$POSTGRES_PASSWORD" ]; then
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    echo "✔ Generated Secure Password"
fi

N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)
N8N_RUNNERS_TOKEN=$(openssl rand -hex 32)
GENERIC_TIMEZONE="Asia/Dhaka"

# Initialize S3 Defaults
S3_ENABLED="false"
S3_BUCKET=""
S3_REGION=""
S3_ACCESS_KEY_ID=""
S3_SECRET_ACCESS_KEY=""
S3_ENDPOINT=""

# --- 3. CONFIG LOGIC ---
if [[ $env_choice =~ ^[Pp]$ ]]; then
    # === PRODUCTION ===
    echo -e "\n${BLUE}--- Production Config ---${NC}"
    while true; do
        read -p "Enter Domain (e.g. n8n.site.com): " RAW_DOMAIN
        DOMAIN_NAME=$(echo "$RAW_DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        if [[ "$DOMAIN_NAME" =~ \. ]]; then break; else echo -e "${RED}Invalid domain.${NC}"; fi
    done
    
    PORT=80
    SSL_PORT=443
    WEBHOOK_URL="https://${DOMAIN_NAME}/"
    N8N_SECURE_COOKIE=true

    # S3 Setup
    echo -e "\n${YELLOW}--- Offsite Backup (S3) ---${NC}"
    read -p "Enable S3 Backups? (y/n): " s3_ask
    if [[ $s3_ask == "y" ]]; then
        S3_ENABLED="true"
        read -p "Bucket Name: " S3_BUCKET
        read -p "Region (e.g. us-east-1): " S3_REGION
        read -p "Access Key ID: " S3_ACCESS_KEY_ID
        read -p "Secret Access Key: " S3_SECRET_ACCESS_KEY
        read -p "Endpoint (Optional): " S3_ENDPOINT
    fi
else
    # === LOCAL ===
    echo -e "\n${BLUE}--- Local Config ---${NC}"
    PORT=8080
    DOMAIN_NAME=":80"
    SSL_PORT=4443
    WEBHOOK_URL="http://localhost:${PORT}/"
    N8N_SECURE_COOKIE=false
fi

# --- 4. GENERATE .ENV ---
cat <<EOT > .env
# Container Identity
CONTAINER_NAME=${CONTAINER_NAME}

# Performance
N8N_DEFAULT_BINARY_DATA_MODE=filesystem

# DB
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=n8n

# App & Security
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_RUNNERS_TOKEN=${N8N_RUNNERS_TOKEN}
GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
WEBHOOK_URL=${WEBHOOK_URL}
N8N_SECURE_COOKIE=${N8N_SECURE_COOKIE}

# Network
DOMAIN_NAME=${DOMAIN_NAME}
PORT=${PORT}
SSL_PORT=${SSL_PORT}

# S3 Backup
S3_ENABLED=${S3_ENABLED}
S3_BUCKET=${S3_BUCKET}
S3_REGION=${S3_REGION}
S3_ACCESS_KEY_ID=${S3_ACCESS_KEY_ID}
S3_SECRET_ACCESS_KEY=${S3_SECRET_ACCESS_KEY}
S3_ENDPOINT=${S3_ENDPOINT}
EOT

echo -e "\n${GREEN}✔ Setup Complete!${NC}"
echo -e "Run: ${BLUE}docker compose up -d --build${NC}"