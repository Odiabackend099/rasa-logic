# Environment Variables Setup

## Summary

I've configured the environment files with your MiniMax credentials. Here's what's been set up:

### ✅ Backend `.env` (Created)

Located at: `backend/.env`

**Already configured:**
- `MINIMAX_API_KEY` - Your MiniMax API key
- `MINIMAX_GROUP_ID` - Your MiniMax Group ID (1933510987994895143)
- `MINIMAX_MODEL` - Set to `speech-02-hd`
- Server port: 3000
- Rasa URLs: localhost defaults

**Still needed:**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_KEY` - Your Supabase anon key

### ⚠️ Rasa Agent `.env` (Template Created)

Located at: `rasa-agent/env.example` (copy to `.env`)

**Needs configuration:**
- `SUPABASE_URL` - Your Supabase project URL  
- `SUPABASE_KEY` - Your Supabase anon key

## Next Steps

1. **Create Supabase Project** (if not done)
   - Go to https://supabase.com
   - Create new project
   - Get project URL and anon key

2. **Update Environment Files**
   
   **rasa-agent/.env:**
   ```bash
   cd rasa-agent
   cp env.example .env
   # Edit .env and add Supabase credentials
   ```

   **backend/.env:**
   ```bash
   # File already exists, just add Supabase credentials:
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-anon-key-here
   ```

3. **Run Database Schema**
   - Open Supabase SQL Editor
   - Copy `database/schema.sql`
   - Execute in SQL Editor

## MiniMax API Configuration

The MiniMax integration has been updated to use:
- API Base URL: `https://api.minimax.chat/v1` (default, can be overridden)
- Endpoints:
  - STT: `/text_to_speech` (for speech-to-text)
  - TTS: `/text_to_speech` (for text-to-speech)
- Authentication: Bearer token in Authorization header
- Model: `speech-02-hd` (as specified)

## Verification

After setting up Supabase, verify connection:

```bash
# Test backend can connect to Supabase
cd backend
node -e "require('dotenv').config(); const { createClient } = require('@supabase/supabase-js'); const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY); console.log('Supabase client created:', !!sb);"
```

## Notes

- `.env` files are in `.gitignore` to prevent committing secrets
- Use `env.example` files as templates
- For production, use environment variable injection or secrets management
- MiniMax API key is already in `backend/.env` - keep it secure!

