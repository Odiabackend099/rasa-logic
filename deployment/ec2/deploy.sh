#!/bin/bash
# Main deployment script for EC2 t3.small
set -euo pipefail

# Configuration
APP_NAME="callwaitingai"
APP_DIR="/home/ec2-user/$APP_NAME"
REPO_URL="https://github.com/Odiabackend099/rasa-logic.git"
BRANCH="main"

echo "🚀 Deploying $APP_NAME to EC2 t3.small..."

# Create application directory
sudo mkdir -p $APP_DIR
sudo chown ec2-user:ec2-user $APP_DIR

# Clone or update repository
if [ -d "$APP_DIR/.git" ]; then
    echo "📥 Updating existing repository..."
    cd $APP_DIR
    git fetch origin
    git reset --hard origin/$BRANCH
else
    echo "📥 Cloning repository..."
    git clone -b $BRANCH $REPO_URL $APP_DIR
    cd $APP_DIR
fi

# Set up environment files
echo "🔧 Setting up environment configuration..."

# Create production environment file
cat > $APP_DIR/backend/.env.production << 'EOF'
# Production Environment for EC2
NODE_ENV=production
PORT=3000

# Rasa Configuration
RASA_SERVER_URL=http://rasa-server:5005
ACTION_SERVER_URL=http://rasa-actions:5055

# Database Configuration (Supabase)
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_KEY=${SUPABASE_KEY}

# MiniMax AI Configuration
MINIMAX_API_URL=https://api.minimax.io/v1/t2a_v2
MINIMAX_API_KEY=${MINIMAX_API_KEY}
MINIMAX_GROUP_ID=${MINIMAX_GROUP_ID}
MINIMAX_MODEL=speech-02-hd

# TTS Configuration
TTS_TIMEOUT_MS=30000
MAX_TEXT_LENGTH=5000

# Twilio Configuration
TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID}
TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN}
TWILIO_PHONE_NUMBER=${TWILIO_PHONE_NUMBER}
TWILIO_WEBHOOK_BASE_URL=${TWILIO_WEBHOOK_BASE_URL}

# WhatsApp Configuration
WHATSAPP_ACCESS_TOKEN=${WHATSAPP_ACCESS_TOKEN}
WHATSAPP_PHONE_NUMBER_ID=${WHATSAPP_PHONE_NUMBER_ID}
WHATSAPP_VERIFY_TOKEN=${WHATSAPP_VERIFY_TOKEN}

# Session Configuration
SESSION_TIMEOUT_MS=86400000
CLEANUP_INTERVAL_MS=3600000

# Security Configuration
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW_MS=900000

# Logging Configuration
LOG_LEVEL=info
ENABLE_DETAILED_ERRORS=false
EOF

# Generate SSL certificates (self-signed for development)
echo "🔐 Generating SSL certificates..."
sudo mkdir -p $APP_DIR/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $APP_DIR/nginx/ssl/key.pem \
    -out $APP_DIR/nginx/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

sudo chown -R ec2-user:ec2-user $APP_DIR/nginx/ssl

# Stop existing containers
echo "🛑 Stopping existing containers..."
cd $APP_DIR
docker-compose down --remove-orphans || true

# Build and start services
echo "🏗️  Building and starting services..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
for service in backend rasa-server rasa-actions; do
    if docker-compose ps $service | grep -q "Up"; then
        echo "✅ $service is running"
    else
        echo "❌ $service failed to start"
        docker-compose logs $service
    fi
done

# Display service URLs
echo "🎉 Deployment completed!"
echo ""
echo "📋 Service Information:"
echo "   - Main Application: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "   - Backend API: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/api"
echo "   - Rasa Server: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/rasa"
echo "   - Health Check: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health"
echo ""
echo "📊 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "🔧 Useful Commands:"
echo "   - View logs: docker-compose logs -f [service]"
echo "   - Restart: docker-compose restart [service]"
echo "   - Update: cd $APP_DIR && git pull && docker-compose up -d --build"