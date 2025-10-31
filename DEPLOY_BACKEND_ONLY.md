# Deploy Backend Only - $7/month Plan

Since you only have a $7/month plan, deploy **just the backend** first.

## Option 1: Manual Service Creation (Recommended for $7 Plan)

### Step 1: Create Backend Service

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **"New +"** → **"Web Service"**
3. Connect repository: `Odiabackend099/ODIADEV-AGENT-LOGIC`
4. Branch: `main`

### Step 2: Configure Service

**General Settings:**
- Name: `callwaitingai-backend`
- Region: Your choice
- Instance Type: **Starter** ($7/month)

**Build & Deploy Settings:**
- Root Directory: **LEAVE EMPTY** (don't set it - Render adds spaces)
- Build Command: `cd backend && npm ci`
- Start Command: `cd backend && npm start`
- Environment: **Node**

**Important:** DO NOT set "Root Directory" field - use `cd` commands instead!

### Step 3: Environment Variables

Add these in **Environment** section:

```
NODE_ENV=production
PORT=10000
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
MINIMAX_API_KEY=your_minimax_api_key
MINIMAX_GROUP_ID=1933510987994895143
MINIMAX_MODEL=speech-02-hd
MINIMAX_API_URL=https://api.minimax.io/v1
LOG_LEVEL=info
```

**Note:** Don't set `RASA_SERVER_URL` yet - you'll add Rasa services later.

### Step 4: Deploy

Click **"Create Web Service"** and wait for deployment (~5 minutes)

---

## Option 2: Use Backend-Only Blueprint

If you want to use Blueprint (but you'll need to upgrade plan later):

1. Use `render-backend-only.yaml` file
2. But still requires plan upgrade for Blueprint feature

**Recommendation:** Use Option 1 (Manual) for $7 plan.

---

## What Works Without Rasa

✅ Backend API endpoints
✅ Health check: `/health`
✅ MiniMax TTS integration
✅ Supabase logging
❌ Chat with Rasa (needs Rasa server)
❌ Conversation AI (needs Rasa)

## Adding Rasa Later

When you can afford more services:

1. **Add Rasa Server** ($7/month)
   - Root Directory: (empty)
   - Build: `cd rasa-agent && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt && pip install -r actions/requirements.txt && rasa train`
   - Start: `cd rasa-agent && source venv/bin/activate && rasa run --enable-api --cors "*" --port $PORT`

2. **Add Rasa Actions** ($7/month)
   - Root Directory: (empty)
   - Build: `cd rasa-agent && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt && pip install -r actions/requirements.txt`
   - Start: `cd rasa-agent && source venv/bin/activate && rasa run actions --port $PORT`

3. **Update Backend** environment variable:
   - `RASA_SERVER_URL=https://rasa-server.onrender.com`
   - `ACTION_SERVER_URL=https://rasa-actions.onrender.com`

## Current Setup: Backend Only

For now, with just backend:
- ✅ API endpoints work
- ✅ Health checks work
- ✅ MiniMax TTS works
- ✅ Supabase logging works
- ❌ Chat won't work (needs Rasa)

## Quick Start

1. **Create service manually** (follow Option 1 above)
2. **Set environment variables**
3. **Deploy**
4. **Test:** `curl https://your-service.onrender.com/health`

Total cost: **$7/month** ✅

