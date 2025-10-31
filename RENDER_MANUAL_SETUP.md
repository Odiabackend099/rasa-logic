# Render Manual Service Configuration

If you created services manually instead of using the Blueprint, follow these settings:

## Backend Service (`callwaitingai-backend` or `Odiadev-TTS`)

### Current Issue
Service is configured as **Docker** but should be **Node.js**.

### Fix: Update Service Settings

1. **Go to Service Settings** → **General** or **Build & Deploy**

2. **Change Service Type**:
   - Look for "Docker" or "Dockerfile Path" setting
   - Remove Dockerfile configuration
   - Or: **Delete service and recreate from Blueprint** (recommended)

3. **If Keeping Manual Setup, Configure:**

**Build & Deploy Settings:**
- **Environment**: `Node`
- **Root Directory**: `backend`
- **Build Command**: `npm ci`
- **Start Command**: `npm start`

**OR use the Blueprint:**

### Recommended: Use Blueprint Instead

1. **Delete current service** (or suspend it)
2. Go to **Dashboard** → **New +** → **Blueprint**
3. Connect repo: `ODIADEV-AGENT-LOGIC`
4. Render will create all services from `render.yaml` automatically

## Service Configuration Reference

### Backend Service Settings

**General:**
- Name: `callwaitingai-backend`
- Region: `Oregon (US West)` (or your preference)
- Instance Type: `Starter` (0.5 CPU, 512 MB RAM)

**Build & Deploy:**
- Repository: `https://github.com/Odiabackend099/ODIADEV-AGENT-LOGIC`
- Branch: `main`
- Root Directory: `backend` ⚠️ **IMPORTANT**
- Environment: `Node` (NOT Docker)
- Build Command: `npm ci`
- Start Command: `npm start`
- Auto-Deploy: `On Commit`

**Environment Variables:**
```
NODE_ENV=production
PORT=10000
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
MINIMAX_API_KEY=your_minimax_key
MINIMAX_GROUP_ID=1933510987994895143
MINIMAX_MODEL=speech-02-hd
MINIMAX_API_URL=https://api.minimax.io/v1
TWILIO_WEBHOOK_BASE_URL=https://callwaitingai-backend.onrender.com
LOG_LEVEL=info
```

**After other services deploy, add:**
```
RASA_SERVER_URL=https://rasa-server.onrender.com
ACTION_SERVER_URL=https://rasa-actions.onrender.com
```

### Rasa Server Settings

**Build & Deploy:**
- Root Directory: `rasa-agent`
- Environment: `Python`
- Build Command:
  ```bash
  python -m venv venv && source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt && pip install -r actions/requirements.txt && rasa train
  ```
- Start Command:
  ```bash
  source venv/bin/activate && rasa run --enable-api --cors "*" --port $PORT
  ```

**Environment Variables:**
```
PORT=10000
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
```

### Rasa Actions Server Settings

**Build & Deploy:**
- Root Directory: `rasa-agent`
- Environment: `Python`
- Build Command:
  ```bash
  python -m venv venv && source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt && pip install -r actions/requirements.txt
  ```
- Start Command:
  ```bash
  source venv/bin/activate && rasa run actions --port $PORT
  ```

**Environment Variables:**
```
PORT=10000
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
```

## Quick Fix for Your Current Service

**Option 1: Delete and Use Blueprint** (Easiest)
1. Delete `Odiadev-TTS` service
2. Go to Dashboard → New + → Blueprint
3. Connect `ODIADEV-AGENT-LOGIC` repo
4. Click "Apply"
5. Set environment variables

**Option 2: Fix Current Service**
1. Go to **Build & Deploy** settings
2. **Remove/Delete Dockerfile Path** (set to empty)
3. Set **Root Directory** to: `backend`
4. Change **Environment** to: `Node` (if option available)
5. Set **Build Command**: `npm ci`
6. Set **Start Command**: `npm start`
7. Save and redeploy

## Verification

After fixing, check build logs:
- Should see: `npm ci` running
- Should see: `npm start` running
- Should NOT see: Docker errors

