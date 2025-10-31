# Production Cleanup Checklist

## 🚨 Issues Found

### 1. Test Files (MUST REMOVE)
These should NOT be in production repo:
- ❌ `backend/test-minimax-tts.js`
- ❌ `backend/test-tts-final.js`
- ❌ `backend/test-tts-autoplay.js`
- ❌ `backend/test-all-voices-autoplay.js`

### 2. Debugging Code (MUST FIX)
Production code with console statements:

**backend/routes/twilio.js:**
- Line 78: `console.log('MiniMax STT transcription:', transcribedText);`
- Line 81: `console.error('STT error:', error);`
- Line 114: `console.log('MiniMax TTS audio generated:', audioUrl.substring(0, 50) + '...');`
- Line 117: `console.error('TTS error:', error);`
- Line 156: `console.error('Rasa error:', error);`
- Line 168: `console.error('Gather error:', error);`
- Line 201: `console.log('Call status:', {...});`
- Line 223: `console.log('Recording received:', {...});`

**backend/services/stt-tts.js:**
- Line 73: `console.error('STT Error:', error.response?.data || error.message);`
- Line 76: `console.warn('STT endpoint not found...');`

### 3. TODO Comments (MUST RESOLVE)
**backend/routes/twilio.js:**
- Line 53: `// TODO: Get audio recording URL from Twilio and process with MiniMax STT`
- Line 210: `// TODO: Update Supabase with call status`
- Line 230: `// TODO: Process recording with MiniMax STT for better accuracy`

**backend/server.js:**
- Line 254: `// TODO: Integrate with actual handoff system`

### 4. Log Files (MUST IGNORE)
- ❌ `backend/combined.log`
- ❌ `backend/error.log`

### 5. Temporary Files (MUST IGNORE)
- ❌ `backend/tmp/` directory (all test MP3 files)

### 6. Hardcoded Paths
**START_SERVICES.sh:**
- Line 19: `BASE_DIR="/Users/odiadev/Desktop/rasa open source"` - Hardcoded path

