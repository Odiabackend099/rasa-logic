# MiniMax Voice Configuration

## Available Voices

### African Voices
- **Odia** (African male default)
  - Voice ID: `moss_audio_4e6eb029-ab89-11f0-a74c-2a7a0b4baedc`
  - Use cases: Default voice, Nigerian Pidgin support
  
- **Joslyn** (African female)
  - Voice ID: `moss_audio_141d8c4c-a6f8-11f0-84c1-0ec6fa858d82`
  - Use cases: Female voice, African English accents

### American Voices
- **Marcus** (American male)
  - Voice ID: `moss_audio_a59cd561-ab87-11f0-a74c-2a7a0b4baedc`
  - Use cases: Standard American English, professional tone
  
- **Marcy** (American female)
  - Voice ID: `moss_audio_fdad4786-ab84-11f0-a816-023f15327f7a`
  - Use cases: Female voice, American English

## Usage

In code, specify the voice name:

```javascript
const { textToSpeech } = require('./services/stt-tts');

// Use Odia (default)
await textToSpeech('Hello', 'en', 'Odia');

// Use Marcus
await textToSpeech('Hello', 'en', 'Marcus');

// Use Marcy
await textToSpeech('Hello', 'en', 'Marcy');

// Use Joslyn
await textToSpeech('Hello', 'en', 'Joslyn');
```

## Configuration

Voice IDs are configured in `backend/services/stt-tts.js`:

- Default voice: **Odia** (African male)
- All voice mappings are case-insensitive
- Falls back to Odia if voice not found

## Voice Selection Logic

The system uses the following voice selection:

1. **Default**: Odia (African male) - for general conversations
2. **Language-based**: Can be set per language (en/pidgin)
3. **Channel-based**: Can be configured per channel (web/telegram/whatsapp/twilio)
4. **User preference**: Can be stored in user session metadata

## API Configuration

- **Group ID**: `1933510987994895143`
- **Model**: `speech-02-hd`
- **Endpoint**: `https://api.minimax.io/v1/t2a_v2`

