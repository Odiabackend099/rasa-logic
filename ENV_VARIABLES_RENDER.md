# Environment Variables for Render Deployment

Copy these environment variables to your Render services.

## 🔴 Required Variables

### Backend Service (`callwaitingai-backend`)

```bash
# Server
NODE_ENV=production
PORT=10000

# Supabase (REQUIRED)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# MiniMax (REQUIRED)
MINIMAX_API_KEY=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
MINIMAX_GROUP_ID=1933510987994895143
MINIMAX_MODEL=speech-02-hd
MINIMAX_API_URL=https://api.minimax.io/v1

# Rasa Services (Set after deployment)
RASA_SERVER_URL=https://rasa-server.onrender.com
ACTION_SERVER_URL=https://rasa-actions.onrender.com

# Webhooks (Update after deployment)
TWILIO_WEBHOOK_BASE_URL=https://callwaitingai-backend.onrender.com

# Logging
LOG_LEVEL=info
```

### Rasa Server (`rasa-server`)

```bash
# Server
PORT=10000

# Supabase (REQUIRED)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Action Server (Set after deployment)
ACTION_SERVER_URL=https://rasa-actions.onrender.com
```

### Rasa Action Server (`rasa-actions`)

```bash
# Server
PORT=10000

# Supabase (REQUIRED)
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🟡 Optional Variables

### Backend Service - Channel Integrations

```bash
# Telegram (Optional)
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# WhatsApp (Optional)
WHATSAPP_PHONE_NUMBER_ID=your_whatsapp_phone_id
WHATSAPP_ACCESS_TOKEN=your_whatsapp_access_token
WHATSAPP_VERIFY_TOKEN=callwaitingai_verify_token

# Redis (Optional - auto-set if Redis service added)
REDIS_URL=redis://... (automatically set by Render)
```

## 📝 Step-by-Step Setup

### 1. Initial Deployment

Set only **required** variables first:
- `SUPABASE_URL`
- `SUPABASE_KEY`
- `MINIMAX_API_KEY`
- `MINIMAX_GROUP_ID`

### 2. After First Deployment

Once services are running, update:

**Backend:**
```
RASA_SERVER_URL=https://rasa-server.onrender.com
ACTION_SERVER_URL=https://rasa-actions.onrender.com
TWILIO_WEBHOOK_BASE_URL=https://callwaitingai-backend.onrender.com
```

**Rasa Server:**
```
ACTION_SERVER_URL=https://rasa-actions.onrender.com
```

### 3. Optional Integrations

Add channel-specific variables only if using those channels.

## 🔒 Security Notes

1. **Never commit** `.env` files to Git
2. **Rotate keys** regularly
3. **Use Render secrets** for sensitive values
4. **Limit access** to Render dashboard

## ✅ Verification

After setting variables, test:

```bash
# Backend health
curl https://callwaitingai-backend.onrender.com/health

# Rasa server
curl -X POST https://rasa-server.onrender.com/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender":"test","message":"hello"}'
```

