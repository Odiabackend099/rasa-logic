# 🔧 Fix Your Current Render Service

## Problem
Your service `Odiadev-TTS` is configured as **Docker** but your repo uses **Node.js build commands**.

## Solution: Two Options

### ✅ Option 1: Delete & Use Blueprint (RECOMMENDED)

This is the easiest and most reliable method:

1. **Delete current service:**
   - Go to service settings
   - Click "Delete Web Service"
   - Confirm deletion

2. **Create Blueprint:**
   - Dashboard → **"New +"** → **"Blueprint"**
   - Repository: `Odiabackend099/ODIADEV-AGENT-LOGIC`
   - Branch: `main`
   - Click **"Apply"**

3. **Set Environment Variables:**
   - Render will prompt for required variables
   - See `ENV_VARIABLES_RENDER.md` for list

4. **Wait for deployment** (~10-15 minutes)

**Benefits:**
- ✅ All services created automatically
- ✅ Correct configuration
- ✅ Service URLs auto-linked
- ✅ No Docker issues

---

### ⚙️ Option 2: Fix Current Service Manually

If you want to keep the current service:

#### Step 1: Change Service Type

1. Go to **Build & Deploy** settings
2. Find **"Dockerfile Path"** setting
3. **Clear/Delete it** or set to empty string
4. **Save changes**

#### Step 2: Configure Node.js Settings

1. **Root Directory** (IMPORTANT):
   - Set to: `backend`
   
2. **Build Command**:
   ```
   npm ci
   ```

3. **Start Command**:
   ```
   npm start
   ```

4. **Environment**:
   - Make sure it's set to **Node** (not Docker)
   - If you see "Docker" option, it means Render still thinks it's Docker

#### Step 3: Update Environment Variables

Add these variables in **Environment** section:

```
NODE_ENV=production
PORT=10000
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key
MINIMAX_API_KEY=your_minimax_key
MINIMAX_GROUP_ID=1933510987994895143
MINIMAX_MODEL=speech-02-hd
MINIMAX_API_URL=https://api.minimax.io/v1
LOG_LEVEL=info
```

#### Step 4: Redeploy

1. Click **"Manual Deploy"**
2. Select **"Clear build cache & deploy"**
3. Monitor build logs

---

## If Option 2 Doesn't Work

If Render still tries to use Docker after clearing Dockerfile path:

**You MUST delete and recreate the service.**

Render's service type is set at creation time. You cannot change from Docker to Node.js on an existing service.

### Recreate Steps:

1. **Note your environment variables** (copy them)
2. **Note your custom domain** (`tts.odia.dev`)
3. **Delete the service**
4. **Create new service manually:**
   - Type: **Web Service**
   - Environment: **Node**
   - Repository: `Odiabackend099/ODIADEV-AGENT-LOGIC`
   - Root Directory: `backend`
   - Build Command: `npm ci`
   - Start Command: `npm start`

OR use Blueprint (Option 1) - much easier!

---

## After Fix - Verify

Check build logs for:
- ✅ `npm ci` command running
- ✅ Node.js installation
- ✅ Package installation
- ❌ NO Docker errors

---

## Recommendation

**Use Option 1 (Blueprint)** because:
- ✅ Automatically creates all 3 services (Backend, Rasa Server, Rasa Actions)
- ✅ Correctly configured from start
- ✅ Service URLs automatically linked
- ✅ Less manual configuration needed

