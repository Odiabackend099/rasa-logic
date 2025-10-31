# 🚀 Render Quick Start Guide

Deploy CallWaitingAI to Render in 5 minutes!

## Prerequisites Checklist

- [ ] Render account created
- [ ] GitHub repo pushed (✅ Done)
- [ ] Supabase project created
- [ ] MiniMax API credentials ready
- [ ] Twilio account (optional)

## Step-by-Step Deployment

### 1. Create Blueprint (Easiest Method)

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **"New +"** → **"Blueprint"**
3. Connect your GitHub account
4. Select repository: **`ODIADEV-AGENT-LOGIC`**
5. Render will detect `render.yaml`
6. Click **"Apply"**

### 2. Set Environment Variables

When prompted, add these environment variables:

#### For Backend Service (`callwaitingai-backend`):

```bash
# Supabase (REQUIRED)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# MiniMax (REQUIRED)
MINIMAX_API_KEY=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
MINIMAX_GROUP_ID=1933510987994895143

# After deployment, update this with your actual URL:
TWILIO_WEBHOOK_BASE_URL=https://callwaitingai-backend.onrender.com

# Optional integrations
TELEGRAM_BOT_TOKEN=your_token_here
WHATSAPP_PHONE_NUMBER_ID=your_id
WHATSAPP_ACCESS_TOKEN=your_token
```

#### For Rasa Services (`rasa-server` and `rasa-actions`):

```bash
# Supabase (REQUIRED)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Wait for Deployment

- **First build**: 10-15 minutes
- **Subsequent builds**: 5-8 minutes

Monitor progress in Render dashboard.

### 4. Get Your Service URLs

After deployment, Render provides URLs:
- Backend: `https://callwaitingai-backend.onrender.com`
- Rasa Server: `https://rasa-server.onrender.com`
- Rasa Actions: `https://rasa-actions.onrender.com`

### 5. Update Webhooks

#### Twilio:
```
Incoming: https://callwaitingai-backend.onrender.com/api/twilio/incoming
Gather: https://callwaitingai-backend.onrender.com/api/twilio/gather
Status: https://callwaitingai-backend.onrender.com/api/twilio/status
```

#### Telegram:
```bash
curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook" \
  -d "url=https://callwaitingai-backend.onrender.com/api/telegram/webhook"
```

#### WhatsApp:
Set in Facebook Developer Console:
```
URL: https://callwaitingai-backend.onrender.com/api/whatsapp/webhook
Verify Token: callwaitingai_verify_token
```

## Testing Your Deployment

### Test Backend:
```bash
curl https://callwaitingai-backend.onrender.com/health
# Expected: {"status":"ok","service":"CallWaitingAI Backend"}
```

### Test Chat:
```bash
curl -X POST https://callwaitingai-backend.onrender.com/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello",
    "session_id": "test-123",
    "channel": "web",
    "language": "en"
  }'
```

### Test Rasa Directly:
```bash
curl -X POST https://rasa-server.onrender.com/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "sender": "test",
    "message": "Hello"
  }'
```

## Troubleshooting

### Service Won't Start
1. Check **Logs** tab in Render dashboard
2. Verify all environment variables are set
3. Check that Python 3.10 is specified

### Build Fails
1. **Python version**: Ensure `runtime.txt` specifies `python-3.10.13`
2. **Missing dependencies**: Check `requirements.txt` includes all packages
3. **Rasa training**: May take 5-10 minutes on first build

### Services Can't Connect
1. Wait 30-60 seconds after deployment (cold start)
2. Verify service URLs in environment variables
3. Check service status (green = running)

### Common Issues

**"Module not found"**:
- Ensure all dependencies in `requirements.txt`
- Check build logs for missing packages

**"Port already in use"**:
- Render sets `PORT` automatically
- Don't hardcode port numbers

**"Rasa model not found"**:
- Ensure `rasa train` runs in build command
- Check that models directory exists

## Service URLs Configuration

After deployment, update these environment variables with actual URLs:

```bash
# In Backend service settings:
RASA_SERVER_URL=https://rasa-server.onrender.com
ACTION_SERVER_URL=https://rasa-actions.onrender.com

# In Rasa Server settings:
ACTION_SERVER_URL=https://rasa-actions.onrender.com
```

## Monitoring

- **Real-time Logs**: View in Render dashboard
- **Metrics**: CPU, memory, request counts
- **Alerts**: Set up email notifications

## Cost

**Free Tier**: Limited (spins down after 15 min)
**Starter**: $7/service = ~$21/month for 3 services

## Next Steps

1. ✅ Deploy services
2. ✅ Test all endpoints
3. ✅ Update webhooks
4. ✅ Monitor logs
5. ✅ Set up alerts

---

**Need Help?** Check `RENDER_DEPLOYMENT.md` for detailed guide.

