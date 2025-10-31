# 🚀 Backend Only - Quick Start ($7/month)

## Fastest Way to Deploy (No Blueprint)

### 1. Create Service (2 minutes)

1. Render Dashboard → **"New +"** → **"Web Service"**
2. Repository: `Odiabackend099/ODIADEV-AGENT-LOGIC`
3. Branch: `main`

### 2. Settings (Copy Exactly)

**Name:** `callwaitingai-backend`

**Build & Deploy:**
- Root Directory: **EMPTY** (don't set it!)
- Build Command: `cd backend && npm ci`
- Start Command: `cd backend && npm start`
- Environment: **Node**

### 3. Environment Variables

Copy-paste these:

```
NODE_ENV=production
PORT=10000
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
MINIMAX_API_KEY=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
MINIMAX_GROUP_ID=1933510987994895143
MINIMAX_MODEL=speech-02-hd
MINIMAX_API_URL=https://api.minimax.io/v1
LOG_LEVEL=info
```

### 4. Deploy

Click **"Create Web Service"**

**Cost: $7/month** ✅

### 5. Test

After deployment:
```bash
curl https://callwaitingai-backend.onrender.com/health
```

Should return:
```json
{"status":"ok","timestamp":"...","rasa_server":"http://localhost:5005"}
```

---

## What Works

✅ All backend endpoints
✅ MiniMax TTS
✅ Supabase logging
❌ Chat (needs Rasa - add later)

---

## Add Rasa Later ($14/month total)

When ready:
1. Create **Rasa Server** service ($7/month)
2. Create **Rasa Actions** service ($7/month)
3. Update backend `RASA_SERVER_URL` env var

**See `DEPLOY_BACKEND_ONLY.md` for Rasa setup steps.**

