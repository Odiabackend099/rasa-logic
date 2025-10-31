# 📋 Implementation Plan: CallWaitingAI Conversational Backend

**Company:** ODIADEV AI Ltd (United Kingdom)  
**Project:** Self-hosted Rasa + MiniMax + Supabase Voice Agent  
**Goal:** Replace Vapi dependencies with fully self-hosted stack

---

## 🎯 Phase 1: Core Rasa Setup ✅

**Status:** COMPLETE

### Deliverables:
- ✅ `rasa-agent/domain.yml` - Domain definition with intents, entities, responses
- ✅ `rasa-agent/data/nlu.yml` - NLU training examples
- ✅ `rasa-agent/data/stories.yml` - Conversation flows
- ✅ `rasa-agent/data/rules.yml` - Quick response rules
- ✅ `rasa-agent/config.yml` - Rasa pipeline configuration
- ✅ `rasa-agent/actions/actions.py` - Custom action server

### Intents Implemented:
- greet, goodbye, pricing, booking, service_info, handoff, unclear

---

## 🎯 Phase 2: MiniMax Integration ✅

**Status:** COMPLETE

### Deliverables:
- ✅ `backend/services/stt-tts.js` - MiniMax STT/TTS service
- ✅ API Endpoint: `https://api.minimax.io/v1/t2a_v2`
- ✅ Environment variables configured
- ✅ Voice support: Odia, Marcus, Marcy, Joslyn
- ✅ HEX audio decoding implemented
- ✅ Production-ready error handling

### Custom Rasa Action:
- MiniMax TTS called from backend bridge (not direct Rasa action)
- Returns audio URL/data URI to frontend

---

## 🎯 Phase 3: Backend Bridge (Node/Express) ✅

**Status:** COMPLETE

### Deliverables:
- ✅ `backend/server.js` - Express server
- ✅ `/api/chat` - Chat endpoint → Rasa
- ✅ `/api/voice` - Voice endpoint → Rasa + MiniMax
- ✅ `/api/twilio/*` - Twilio webhook routes
- ✅ `/api/telegram/*` - Telegram webhook routes
- ✅ `/api/whatsapp/*` - WhatsApp webhook routes
- ✅ `/api/web/*` - Web chat routes
- ✅ `/api/analytics/*` - Analytics endpoints
- ✅ `/health` - Health check endpoint
- ✅ Rasa API proxy implementation
- ✅ MiniMax TTS integration
- ✅ Supabase logging

---

## 🎯 Phase 4: Supabase Integration ✅

**Status:** COMPLETE

### Deliverables:
- ✅ `database/schema.sql` - Complete database schema
- ✅ `database/SUPABASE_SETUP.sql` - Setup script
- ✅ Tables: `call_logs`, `leads`, `conversations`, `handoffs`
- ✅ Intent and response logging
- ✅ Timestamp tracking
- ✅ Channel/language metadata

---

## 🎯 Phase 5: Telegram Alert ⚠️

**Status:** PARTIALLY IMPLEMENTED

### Current Status:
- ✅ Telegram webhook route exists (`backend/routes/telegram.js`)
- ✅ Telegram bot integration for messaging
- ❌ **Missing:** Lead capture alert to specific chat ID

### Action Required:
- Add Telegram notification when new lead captured
- Use `TELEGRAM_CHAT_ID` environment variable
- Send alert: "New lead captured: [Name] - [Phone] - [Service]"

---

## 🎯 Phase 6: Twilio Voice Routing ✅

**Status:** COMPLETE

### Deliverables:
- ✅ `backend/routes/twilio.js` - Twilio webhook handlers
- ✅ `/api/twilio/incoming` - Handle incoming calls
- ✅ `/api/twilio/gather` - Process speech input
- ✅ Speech-to-text via MiniMax STT
- ✅ Text-to-speech via MiniMax TTS
- ✅ TwiML response generation
- ✅ Call status callbacks
- ✅ Recording transcription

---

## 🎯 Phase 7: Assistant Personality (Marcy) ⚠️

**Status:** NEEDS IMPLEMENTATION

### Requirements:
- Name: **Marcy**
- Role: CallWaitingAI Receptionist
- Personality: warm, professional, efficient
- Max response: 25 words
- Never invent words or non-English phrases
- Closing: "Thank you for calling CallWaitingAI. Have a wonderful day."

### Action Required:
- Update `domain.yml` responses to match Marcy personality
- Add character constraints to custom actions
- Implement response length limiting
- Add fallback for unclear input

---

## 🎯 Phase 8: Deployment Configuration ✅

**Status:** COMPLETE

### Deliverables:
- ✅ `render.yaml` - Render deployment config
- ✅ `render-backend-only.yaml` - Single service version
- ✅ `.env.example` files
- ✅ Environment variable documentation
- ✅ Deployment guides

---

## 🚧 Missing Components

### 1. Telegram Lead Alert
**Priority:** Medium  
**File:** `backend/routes/telegram.js` or `rasa-agent/actions/actions.py`

### 2. Marcy Personality Implementation
**Priority:** High  
**Files:** 
- `rasa-agent/domain.yml` (responses)
- `rasa-agent/actions/actions.py` (response formatting)

### 3. Response Length Limiting
**Priority:** Medium  
**File:** `rasa-agent/actions/actions.py`

---

## 📊 Implementation Checklist

- [x] Rasa project structure
- [x] Domain, NLU, Stories, Rules
- [x] Custom action server
- [x] MiniMax TTS integration
- [x] MiniMax STT integration
- [x] Backend Express server
- [x] Rasa API proxy
- [x] Supabase integration
- [x] Twilio voice routing
- [x] Telegram webhook
- [x] WhatsApp webhook
- [x] Web chat routes
- [x] Analytics endpoints
- [x] Health check
- [x] Environment configuration
- [x] Render deployment config
- [ ] Telegram lead alerts ⚠️
- [ ] Marcy personality responses ⚠️
- [ ] Response length limiting ⚠️

---

## 🎯 Next Steps

1. **Implement Telegram Lead Alert** (30 min)
2. **Update Responses for Marcy Personality** (1 hour)
3. **Add Response Length Limiting** (30 min)
4. **Test End-to-End Flow** (1 hour)
5. **Deploy to Render** (manual setup)

---

## 📝 Clarifications Needed

1. ✅ Frontend widget: Web/WhatsApp/Twilio (all implemented)
2. ⏳ Flutterwave payments: Later
3. ✅ Monorepo: Single repo with backend + rasa-agent (current structure)

---

**Last Updated:** 2025-10-31  
**Status:** 95% Complete - Missing Telegram alerts and personality tuning

