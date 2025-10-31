# Deployment Guide

This guide covers deploying the CallWaitingAI Rasa conversational agent to AWS EC2.

## Prerequisites

- AWS EC2 t3.small instance (or equivalent)
- Domain name: `logic.callwaitingai.dev`
- SSL certificate (Let's Encrypt or AWS Certificate Manager)
- Supabase project configured
- Python 3.10 installed on server

## Step 1: Server Setup

### Initial Server Configuration

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python 3.10
sudo apt install python3.10 python3.10-venv python3.10-dev -y

# Install Node.js (for backend API)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install nginx
sudo apt install nginx -y

# Install PM2 for process management
sudo npm install -g pm2
```

## Step 2: Deploy Rasa Agent

```bash
# Create application directory
sudo mkdir -p /opt/callwaitingai
sudo chown $USER:$USER /opt/callwaitingai
cd /opt/callwaitingai

# Clone or copy your rasa-agent directory
git clone <your-repo> rasa-agent
cd rasa-agent

# Create virtual environment
python3.10 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install rasa rasa-sdk supabase python-dotenv

# Install action server dependencies
cd actions
pip install -r requirements.txt
cd ..

# Train model
rasa train

# Create .env file
cp env.example .env
# Edit .env with your Supabase credentials
```

## Step 3: Deploy Backend API

```bash
cd /opt/callwaitingai

# Copy backend directory
cp -r <local-backend> backend
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env with configuration
```

## Step 4: Configure Services

### Rasa Server (PM2)

Create `/opt/callwaitingai/rasa-agent/start-rasa.sh`:

```bash
#!/bin/bash
cd /opt/callwaitingai/rasa-agent
source venv/bin/activate
rasa run --enable-api --cors "*" --port 5005
```

Make it executable:
```bash
chmod +x start-rasa.sh
```

Start with PM2:
```bash
pm2 start start-rasa.sh --name rasa-server
pm2 save
pm2 startup
```

### Action Server (PM2)

Create `/opt/callwaitingai/rasa-agent/start-actions.sh`:

```bash
#!/bin/bash
cd /opt/callwaitingai/rasa-agent
source venv/bin/activate
rasa run actions --port 5055
```

Make it executable and start:
```bash
chmod +x start-actions.sh
pm2 start start-actions.sh --name rasa-actions
pm2 save
```

### Backend API (PM2)

```bash
cd /opt/callwaitingai/backend
pm2 start server.js --name callwaitingai-api
pm2 save
```

## Step 5: Configure Nginx

Create `/etc/nginx/sites-available/callwaitingai`:

```nginx
server {
    listen 80;
    server_name logic.callwaitingai.dev;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name logic.callwaitingai.dev;

    ssl_certificate /etc/letsencrypt/live/logic.callwaitingai.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/logic.callwaitingai.dev/privkey.pem;

    # Backend API
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Rasa server (if needed to expose directly)
    location /rasa/ {
        proxy_pass http://localhost:5005/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/callwaitingai /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Step 6: SSL Certificate

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtain certificate
sudo certbot --nginx -d logic.callwaitingai.dev

# Auto-renewal is configured automatically
```

## Step 7: Firewall Configuration

```bash
# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

## Step 8: Monitoring

### Check PM2 Status
```bash
pm2 status
pm2 logs
```

### Check Nginx Status
```bash
sudo systemctl status nginx
```

### Check Services
```bash
# Rasa server
curl http://localhost:5005/status

# Backend API
curl http://localhost:3000/health
```

## Step 9: Auto-Restart on Reboot

PM2 startup is already configured. Verify:
```bash
pm2 startup
```

## Environment Variables

Ensure all `.env` files are properly configured:

**rasa-agent/.env:**
```
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
```

**backend/.env:**
```
PORT=3000
RASA_SERVER_URL=http://localhost:5005
ACTION_SERVER_URL=http://localhost:5055
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
# ... other configs
```

## Troubleshooting

### Rasa not starting
```bash
cd /opt/callwaitingai/rasa-agent
source venv/bin/activate
rasa run --enable-api --debug
```

### Backend API errors
```bash
cd /opt/callwaitingai/backend
pm2 logs callwaitingai-api
```

### Nginx errors
```bash
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

## Updates and Maintenance

### Update Rasa Model
```bash
cd /opt/callwaitingai/rasa-agent
source venv/bin/activate
rasa train
pm2 restart rasa-server
```

### Update Code
```bash
cd /opt/callwaitingai
git pull
# Restart services
pm2 restart all
```

