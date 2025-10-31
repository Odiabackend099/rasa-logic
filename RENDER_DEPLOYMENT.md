# Render Deployment Guide

This guide walks you through deploying CallWaitingAI on Render.

## Prerequisites

1. **Render Account**: Sign up at [render.com](https://render.com)
2. **GitHub Repository**: Your code should be pushed to GitHub
3. **Supabase Project**: Set up your Supabase database (see `database/SUPABASE_SETUP.sql`)
4. **API Keys**: Have your MiniMax, Twilio, Telegram, WhatsApp credentials ready

## Architecture

The deployment consists of 4 services:

1. **Backend API** (Node.js) - Port 10000
2. **Rasa Server** (Python) - Port 10000  
3. **Rasa Action Server** (Python) - Port 10000
4. **Redis Cache** (Optional) - For session storage

## Deployment Steps

### Option 1: Using render.yaml (Recommended)

1. **Push your code to GitHub** (already done ✅)

2. **Create a new Blueprint** in Render:
   - Go to Dashboard → New → Blueprint
   - Connect your GitHub repository
   - Select `render.yaml` from the repo
   - Click "Apply"

3. **Set Environment Variables**:
   Render will prompt you to set the following variables:
   
   **Backend Service:**
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_KEY=your_supabase_anon_key
   MINIMAX_API_KEY=your_minimax_api_key
   MINIMAX_GROUP_ID=your_minimax_group_id
   TWILIO_WEBHOOK_BASE_URL=https://callwaitingai-backend.onrender.com
   TELEGRAM_BOT_TOKEN=your_telegram_token (optional)
   WHATSAPP_PHONE_NUMBER_ID=your_whatsapp_id (optional)
   WHATSAPP_ACCESS_TOKEN=your_whatsapp_token (optional)
   ```
   
   **Rasa Services:**
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_KEY=your_supabase_anon_key
   ```

4. **Wait for Build and Deploy** (~10-15 minutes for first build)

### Option 2: Manual Service Creation

If you prefer to create services manually:

#### 1. Create Backend API Service

- **Type**: Web Service
- **Name**: `callwaitingai-backend`
- **Repository**: Your GitHub repo
- **Root Directory**: `backend`
- **Environment**: Node
- **Build Command**: `npm install`
- **Start Command**: `npm start`
- **Plan**: Starter ($7/month) or Free (with limitations)

**Environment Variables:**
```
NODE_ENV=production
PORT=10000
RASA_SERVER_URL=https://rasa-server.onrender.com
ACTION_SERVER_URL=https://rasa-actions.onrender.com
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
MINIMAX_API_KEY=your_minimax_api_key
MINIMAX_GROUP_ID=your_minimax_group_id
MINIMAX_MODEL=speech-02-hd
MINIMAX_API_URL=https://api.minimax.io/v1
TWILIO_WEBHOOK_BASE_URL=https://callwaitingai-backend.onrender.com
LOG_LEVEL=info
```

#### 2. Create Rasa Server

- **Type**: Web Service
- **Name**: `rasa-server`
- **Repository**: Your GitHub repo
- **Root Directory**: `rasa-agent`
- **Environment**: Python 3.10
- **Build Command**: 
  ```bash
  python -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r actions/requirements.txt
  rasa train
  ```
- **Start Command**: 
  ```bash
  source venv/bin/activate
  rasa run --enable-api --cors "*" --port $PORT
  ```
- **Plan**: Starter ($7/month)

**Environment Variables:**
```
PORT=10000
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
ACTION_SERVER_URL=https://rasa-actions.onrender.com
```

#### 3. Create Rasa Action Server

- **Type**: Web Service
- **Name**: `rasa-actions`
- **Repository**: Your GitHub repo
- **Root Directory**: `rasa-agent`
- **Environment**: Python 3.10
- **Build Command**: 
  ```bash
  python -m venv venv
  source venv/bin/activate
  pip install --upgrade pip
  pip install -r actions/requirements.txt
  ```
- **Start Command**: 
  ```bash
  source venv/bin/activate
  rasa run actions --port $PORT
  ```
- **Plan**: Starter ($7/month)

**Environment Variables:**
```
PORT=10000
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
```

#### 4. Create Redis Cache (Optional)

- **Type**: Redis
- **Name**: `redis-cache`
- **Plan**: Starter ($10/month) or Free
- **Max Memory Policy**: allkeys-lru

The Redis connection string will be automatically set as `REDIS_URL` in the backend service.

## Post-Deployment Configuration

### 1. Update Twilio Webhooks

After deployment, update your Twilio webhooks to point to:
```
https://callwaitingai-backend.onrender.com/api/twilio/incoming
https://callwaitingai-backend.onrender.com/api/twilio/gather
https://callwaitingai-backend.onrender.com/api/twilio/status
```

### 2. Update Telegram Webhook

Set Telegram webhook:
```bash
curl -X POST "https://api.telegram.org/bot<YOUR_TOKEN>/setWebhook" \
  -d "url=https://callwaitingai-backend.onrender.com/api/telegram/webhook"
```

### 3. Update WhatsApp Webhook

In Facebook Developer Console:
- Webhook URL: `https://callwaitingai-backend.onrender.com/api/whatsapp/webhook`
- Verify Token: `callwaitingai_verify_token` (or your custom token)

### 4. Verify Services

Check service health:
```bash
# Backend
curl https://callwaitingai-backend.onrender.com/health

# Rasa Server
curl https://rasa-server.onrender.com/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender":"test","message":"hello"}'
```

## Environment Variables Reference

### Required Variables

| Variable | Service | Description |
|----------|---------|-------------|
| `SUPABASE_URL` | All | Supabase project URL |
| `SUPABASE_KEY` | All | Supabase anon key |
| `MINIMAX_API_KEY` | Backend | MiniMax API key |
| `MINIMAX_GROUP_ID` | Backend | MiniMax group ID |

### Optional Variables

| Variable | Service | Description |
|----------|---------|-------------|
| `TWILIO_WEBHOOK_BASE_URL` | Backend | Your Render backend URL |
| `TELEGRAM_BOT_TOKEN` | Backend | Telegram bot token |
| `WHATSAPP_PHONE_NUMBER_ID` | Backend | WhatsApp business phone ID |
| `WHATSAPP_ACCESS_TOKEN` | Backend | WhatsApp access token |
| `REDIS_URL` | Backend | Redis connection (auto-set) |
| `LOG_LEVEL` | Backend | Logging level (default: info) |

## Troubleshooting

### Build Failures

1. **Python Version Issues**: Ensure Python 3.10 is specified
2. **Rasa Training Fails**: Check that all dependencies are in `actions/requirements.txt`
3. **Port Conflicts**: Render automatically sets `PORT`, don't hardcode it

### Runtime Issues

1. **Service Not Starting**: Check logs in Render dashboard
2. **CORS Errors**: Ensure Rasa server has `--cors "*"` in start command
3. **Connection Timeouts**: Services may take 30-60 seconds to start

### Common Fixes

1. **Rasa Model Not Found**: 
   - Ensure `rasa train` runs in build command
   - Check that `models/` directory exists

2. **Action Server Not Responding**:
   - Verify `ACTION_SERVER_URL` is correct in Rasa server env
   - Check action server logs

3. **Backend Can't Connect to Rasa**:
   - Verify service URLs are correct
   - Wait for all services to finish deploying
   - Check service status in Render dashboard

## Cost Estimate

**Free Tier** (Limited):
- 1 service at a time
- Spins down after 15 min inactivity
- Good for testing only

**Starter Plan** (Recommended):
- Backend: $7/month
- Rasa Server: $7/month
- Rasa Actions: $7/month
- Redis: $10/month (optional)
- **Total: ~$31/month** (with Redis)

## Monitoring

1. **Logs**: View real-time logs in Render dashboard
2. **Metrics**: Monitor CPU, memory, and requests
3. **Alerts**: Set up email alerts for service failures

## Next Steps

1. Deploy using render.yaml (Option 1) or manually (Option 2)
2. Set all environment variables
3. Wait for services to build and deploy
4. Update webhook URLs in external services
5. Test all integrations
6. Monitor logs for any issues

## Support

For issues:
1. Check Render dashboard logs
2. Review service status pages
3. Verify environment variables
4. Check service connectivity

