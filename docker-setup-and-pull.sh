#!/bin/bash

set -e

echo "========================================="
echo " Docker + Docker Compose Initialization"
echo "========================================="

# -----------------------------------------
# 1. Update Ubuntu
# -----------------------------------------

echo "[1/8] Updating Ubuntu packages..."

sudo apt update
sudo apt upgrade -y


# -----------------------------------------
# 2. Install Docker prerequisites
# -----------------------------------------

echo "[2/8] Installing Docker prerequisites..."

sudo apt install -y \
    ca-certificates \
    curl \
    gnupg


# -----------------------------------------
# 3. Add Docker GPG key
# -----------------------------------------

echo "[3/8] Adding Docker GPG key..."

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg


# -----------------------------------------
# 4. Add Docker repository
# -----------------------------------------

echo "[4/8] Adding Docker repository..."

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update


# -----------------------------------------
# 5. Install Docker Engine + Compose
# -----------------------------------------

echo "[5/8] Installing Docker..."

sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin


# -----------------------------------------
# 6. Enable Docker
# -----------------------------------------

echo "[6/8] Starting Docker..."

sudo systemctl enable docker
sudo systemctl start docker

sudo systemctl status docker --no-pager


# -----------------------------------------
# 7. Allow current user to use Docker
# -----------------------------------------

echo "[7/8] Configuring Docker permissions..."

sudo usermod -aG docker "$USER"


# -----------------------------------------
# 8. Create application directory
# -----------------------------------------

echo "[8/8] Creating application directory..."

mkdir -p "$HOME/nodejs-docker"
cd "$HOME/nodejs-docker"


# -----------------------------------------
# Docker Hub image
# -----------------------------------------

DOCKER_IMAGE="tanviralamdevops/nodejsstarter:tagname"

echo "Pulling Docker Hub image:"
echo "$DOCKER_IMAGE"

sudo docker pull "$DOCKER_IMAGE"


# -----------------------------------------
# Create nginx.conf
# -----------------------------------------

echo "Creating nginx.conf..."

cat > nginx.conf <<'EOF'
server {
    listen 80;

    location / {
        proxy_pass http://app:5000;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF


# -----------------------------------------
# Create docker-compose.yml
# -----------------------------------------

echo "Creating docker-compose.yml..."

cat > docker-compose.yml <<EOF
services:

  nginx:
    image: nginx:alpine
    container_name: assessment-nginx

    ports:
      - "8080:80"

    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro

    networks:
      - app-network

  app:
    image: $DOCKER_IMAGE
    container_name: assessment-app

    expose:
      - "5000"

    depends_on:
      - nginx

    networks:
      - app-network

networks:
  app-network:
    driver: bridge
EOF


# -----------------------------------------
# Show files
# -----------------------------------------

echo ""
echo "========================================="
echo " Deployment files created"
echo "========================================="

ls -la

echo ""
echo "Docker version:"
sudo docker --version

echo ""
echo "Docker Compose version:"
sudo docker compose version

echo ""
echo "Docker Hub image:"
sudo docker images "$DOCKER_IMAGE"


# -----------------------------------------
# Start application
# -----------------------------------------

echo ""
echo "Starting Docker Compose..."

sudo docker compose up -d


# -----------------------------------------
# Status
# -----------------------------------------

echo ""
echo "========================================="
echo " Application Status"
echo "========================================="

sudo docker compose ps

echo ""
echo "========================================="
echo " Deployment Complete"
echo "========================================="

echo ""
echo "Application URL:"
echo "http://$(curl -s ifconfig.me):8080"

echo ""
echo "Local test:"
echo "curl http://localhost:8080"

echo ""
echo "========================================="
