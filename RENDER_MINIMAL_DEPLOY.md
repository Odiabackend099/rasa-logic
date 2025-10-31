# Minimal Render Deployment ($7/month)

## Current Situation

You have a $7/month plan, but the full Blueprint requires $31/month (4 services).

## Options

### Option 1: Deploy Backend Only First ($7/month)

Start with just the backend service, then add Rasa services later.

**Steps:**
1. Don't use Blueprint for now
2. Create service manually (see below)
3. Add Rasa services later when budget allows

### Option 2: Upgrade Plan

Upgrade to accommodate all services:
- $21/month for 3 web services (Backend + 2 Rasa)
- $10/month for Redis (optional)
- Total: $31/month

### Option 3: Modified Blueprint (Recommended)

I've updated `render.yaml` to:
- ✅ Keep all 3 web services (Backend, Rasa Server, Rasa Actions)
- ❌ Remove Redis (optional, saves $10/month)
- **Cost: $21/month** (3 services × $7)

You'll need to upgrade to accommodate 3 services.

---

## Quick Start: Backend Only ($7/month)

### Manual Service Creation

1. **Create Backend Service:**
   - Dashboard → "New +" → "Web Service"
   - Repository: `Odiabackend099/ODIADEV-AGENT-LOGIC`
   - Branch: `main`
   - Root Directory: `backend`
   - Environment: `Node`
   - Build Command: `npm ci`
   - Start Command: `npm start`
   - Plan: Starter ($7/month)

2. **Environment Variables:**
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

3. **Deploy**

**Note:** Backend will work, but Rasa features won't be available until you add Rasa services.

---

## Recommended: Upgrade for Full Deployment

To get the complete system working:

1. **Upgrade Render Plan** to support 3+ services
2. **Use the updated Blueprint** (Redis removed - saves $10/month)
3. **Total cost: $21/month** instead of $31/month

The updated `render.yaml` has Redis commented out, so it will create:
- ✅ Backend ($7/month)
- ✅ Rasa Server ($7/month)  
- ✅ Rasa Actions ($7/month)
- ❌ Redis (removed to save costs)

**Total: $21/month**

You can add Redis later if needed for session storage.

---

## Next Steps

1. **If you want full system**: Upgrade plan → Use Blueprint
2. **If you want to start small**: Deploy Backend manually first
3. **If budget allows**: Use the updated Blueprint (now $21/month instead of $31)

