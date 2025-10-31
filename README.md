# CallWaitingAI - Rasa Conversational Agent

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/docs/blueprint-spec)

Self-hosted Rasa Open Source conversational AI system to replace VAPI's conversation logic for CallWaitingAI.

## Project Structure

```
.
├── rasa-agent/          # Rasa Open Source agent
│   ├── data/           # Training data (NLU, stories, rules)
│   ├── actions/        # Custom action server
│   ├── models/         # Trained Rasa models
│   ├── config.yml      # Rasa configuration
│   ├── domain.yml      # Domain definition
│   └── endpoints.yml   # Endpoint configuration
├── backend/            # Node.js/Express API server
│   ├── routes/         # API route handlers
│   ├── services/       # Service integrations (STT/TTS)
│   └── server.js       # Main server file
└── database/           # Supabase database schema
    └── schema.sql      # Database schema

```

## Features

- **Multi-language Support**: English and Nigerian Pidgin
- **Multi-channel Integration**: Web, Telegram, WhatsApp, Twilio voice calls
- **Lead Capture**: Automatic lead capture and storage in Supabase
- **Human Handoff**: Seamless transfer to human agents
- **Analytics Dashboard**: Conversation analytics and reporting
- **Voice Integration**: Twilio + MiniMax STT/TTS support

## Quick Start

### Prerequisites

- Python 3.10 (3.11+ not compatible with Rasa 3.x)
- Node.js 18+
- Supabase account

### Local Development Setup

1. **Setup Rasa Agent**

```bash
cd rasa-agent
python3.10 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install --upgrade pip
pip install rasa rasa-sdk supabase python-dotenv

# Install action server dependencies
cd actions
pip install -r requirements.txt
cd ..

# Copy environment file
cp env.example .env
# Edit .env with your Supabase credentials

# Train model
rasa train
```

2. **Start Rasa Services**

Terminal 1 - Rasa server:
```bash
cd rasa-agent
source venv/bin/activate
rasa run --enable-api --cors "*"
```

Terminal 2 - Action server:
```bash
cd rasa-agent
source venv/bin/activate
rasa run actions
```

3. **Setup Backend API**

```bash
cd backend
npm install

# Copy environment file
cp .env.example .env
# Edit .env with configuration

# Start server
npm start
# Or for development:
npm run dev
```

4. **Setup Database**

- Create Supabase project
- Run `database/schema.sql` in Supabase SQL Editor
- Configure environment variables in both `rasa-agent/.env` and `backend/.env`

## Configuration

### Environment Variables

**rasa-agent/.env:**
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_KEY`: Your Supabase anon key

**backend/.env:**
- `PORT`: Backend server port (default: 3000)
- `RASA_SERVER_URL`: Rasa server URL (default: http://localhost:5005)
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_KEY`: Your Supabase anon key
- `MINIMAX_STT_URL`: MiniMax STT API URL (optional)
- `MINIMAX_TTS_URL`: MiniMax TTS API URL (optional)
- `MINIMAX_API_KEY`: MiniMax API key (optional)
- `TELEGRAM_BOT_TOKEN`: Telegram bot token (optional)
- `WHATSAPP_PHONE_NUMBER_ID`: WhatsApp Business API phone number ID (optional)
- `WHATSAPP_ACCESS_TOKEN`: WhatsApp access token (optional)

## API Endpoints

### Chat & Voice

- `POST /api/chat` - Process chat message
- `POST /api/voice` - Process voice message (STT text)
- `GET /api/session/:sessionId` - Get conversation history
- `POST /api/handoff` - Trigger human handoff

### Twilio

- `POST /api/twilio/incoming` - Handle incoming Twilio call
- `POST /api/twilio/gather` - Handle speech input
- `POST /api/twilio/status` - Call status callback

### Channels

- `POST /api/telegram/webhook` - Telegram webhook
- `POST /api/whatsapp/webhook` - WhatsApp webhook

### Analytics

- `GET /api/analytics/dashboard` - Dashboard summary
- `GET /api/analytics/conversations` - Conversation list
- `GET /api/analytics/intents` - Intent statistics
- `GET /api/analytics/leads` - Lead statistics
- `GET /api/analytics/session/:sessionId` - Session details

## Training the Model

```bash
cd rasa-agent
source venv/bin/activate
rasa train
```

## Testing

### Test Rasa directly:

```bash
cd rasa-agent
source venv/bin/activate
rasa shell
```

### Test via API:

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "session_id": "test123"}'
```

## Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for AWS EC2 deployment instructions.

## License

Apache 2.0 (same as Rasa Open Source)

## Support

For issues and questions, please refer to:
- [Rasa Documentation](https://rasa.com/docs/rasa)
- Project documentation in individual directories

