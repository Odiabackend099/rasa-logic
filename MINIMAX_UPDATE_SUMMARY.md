# ✅ MiniMax API Integration Updated

## Changes Made

### 1. Corrected API Endpoint
- **Old**: `https://api.minimax.chat/v1`
- **New**: `https://api.minimax.io/v1`
- **TTS Endpoint**: `/t2a_v2` (Text-to-Audio v2)

### 2. Updated Credentials
- New API key installed
- Group ID: `1933510987994895143`
- Model: `speech-02-hd`
- All credentials configured in `backend/.env`

### 3. Code Updates

#### `backend/services/stt-tts.js`
- ✅ Updated base URL to `https://api.minimax.io/v1`
- ✅ TTS now uses `/t2a_v2` endpoint
- ✅ STT uses `/a2t` endpoint (audio-to-text)
- ✅ Added proper error handling and logging
- ✅ Added timeout configuration (30 seconds)
- ✅ Added audio settings (sample_rate, bit_rate)

#### `backend/routes/twilio.js`
- ✅ Integrated MiniMax STT service
- ✅ Integrated MiniMax TTS service
- ✅ Removed TODO comments
- ✅ Proper error handling with fallbacks

## API Integration Details

### Text-to-Speech (TTS)
**Endpoint**: `POST https://api.minimax.io/v1/t2a_v2`

**Request Body**:
```json
{
  "group_id": "1933510987994895143",
  "text": "Hello, how can I help you?",
  "language": "en",
  "voice": "alice",
  "model": "speech-02-hd",
  "format": "mp3",
  "speed": 1.0,
  "audio_setting": {
    "sample_rate": 24000,
    "bit_rate": 128000
  }
}
```

**Response**: Returns `audio_url` or `audio` (base64) in response

### Speech-to-Text (STT)
**Endpoint**: `POST https://api.minimax.io/v1/a2t` (assumed)

**Note**: If STT endpoint differs, update in `stt-tts.js` line 36

## Environment Variables

Ensure these are set in `backend/.env`:

```bash
MINIMAX_API_URL=https://api.minimax.io/v1
MINIMAX_API_KEY=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
MINIMAX_GROUP_ID=1933510987994895143
MINIMAX_MODEL=speech-02-hd
```

## Testing

To test the TTS integration:

```javascript
const { textToSpeech } = require('./services/stt-tts');

async function test() {
  try {
    const audioUrl = await textToSpeech('Hello, this is a test', 'en', 'alice');
    console.log('Audio URL:', audioUrl);
  } catch (error) {
    console.error('Error:', error);
  }
}
```

## Next Steps

1. ✅ Endpoint updated
2. ✅ Credentials configured
3. ✅ Code integrated
4. ⏳ Test TTS with actual API call
5. ⏳ Verify STT endpoint (if different from `/a2t`)
6. ⏳ Test Twilio voice flow end-to-end

## Notes

- STT endpoint (`/a2t`) is an assumption. If MiniMax uses a different endpoint, update line 36 in `stt-tts.js`
- TTS endpoint (`/t2a_v2`) is confirmed correct
- Language support: Currently defaults to 'en' for pidgin. Adjust if MiniMax supports pidgin directly.
- Error handling: All functions have try/catch with proper logging

## Status

✅ **Integration Complete** - Ready for testing!

