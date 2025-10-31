#!/bin/bash
# Setup script for environment variables

echo "=================================="
echo "CallWaitingAI Environment Setup"
echo "=================================="
echo ""

# Backend .env setup
echo "Setting up backend/.env..."
if [ ! -f "backend/.env" ]; then
  cat > backend/.env << 'EOF'
# Server Configuration
PORT=3000
NODE_ENV=development

# Rasa Configuration
RASA_SERVER_URL=http://localhost:5005
ACTION_SERVER_URL=http://localhost:5055

# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key

# MiniMax Configuration
MINIMAX_API_KEY=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJHcm91cE5hbWUiOiJPRElBIGJhY2tlbmQiLCJVc2VyTmFtZSI6Ik9ESUEgYmFja2VuZCIsIkFjY291bnQiOiIiLCJTdWJqZWN0SUQiOiIxOTMzNTEwOTg4MDAzMjgzNzUxIiwiUGhvbmUiOiIiLCJHcm91cElEIjoiMTkzMzUxMDk4Nzk5NDg5NTE0MyIsIlBhZ2VOYW1lIjoiIiwiTWFpbCI6Im9kaWFiYWNrZW5kQGdtYWlsLmNvbSIsIkNyZWF0ZVRpbWUiOiIyMDI1LTEwLTIyIDA1OjM3OjQ4IiwiVG9rZW5UeXBlIjoxLCJpc3MiOiJtaW5pbWF4In0.gnJPHryijRFlHDdAI_oN-RSSipVHLL4b6kalvDuJ20nmxHapULV9NPrHyraHJKleuhBVSMzaQa3nR5f77ggfx9Hvq5b6Gbis-yYTwfzggk9Qy7uhOlPC_3-MMTGpz9cYbFxaehmu7nR8a3MGce8roKyvvuhtPDG8QiE7wUBYvh3bv3JEXtJuj6exQOIHNXqYUDBZ1ucqf0HUbtwZ1KYlrFBnAmh6aLZHN1Z-4p7jHX5TVGlzCAfRsxf0rdHTpGiCfgbPyyr571xWQAjyUugsUOPWwcMlLcYeeT4LlUS1fz6PBVHC9Ij22DjOqYu8yX_In6PUy8N6T8P9xBeqE2XS0Q
MINIMAX_GROUP_ID=1933510987994895143
MINIMAX_MODEL=speech-02-hd
MINIMAX_API_URL=https://api.minimax.chat/v1

# Redis (optional, for production session storage)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Twilio Configuration (if using)
TWILIO_WEBHOOK_BASE_URL=https://logic.callwaitingai.dev
AGENT_PHONE_NUMBER=

# Telegram Bot (optional)
TELEGRAM_BOT_TOKEN=

# WhatsApp Business API (optional)
WHATSAPP_PHONE_NUMBER_ID=
WHATSAPP_ACCESS_TOKEN=
WHATSAPP_VERIFY_TOKEN=callwaitingai_verify_token

# Logging
LOG_LEVEL=info
EOF
  echo "✅ Created backend/.env with MiniMax credentials pre-configured"
else
  echo "⚠️  backend/.env already exists - skipping"
fi

# Rasa agent .env setup
echo ""
echo "Setting up rasa-agent/.env..."
if [ ! -f "rasa-agent/.env" ]; then
  cp rasa-agent/env.example rasa-agent/.env
  echo "✅ Created rasa-agent/.env from template"
else
  echo "⚠️  rasa-agent/.env already exists - skipping"
fi

echo ""
echo "=================================="
echo "Next Steps:"
echo "=================================="
echo ""
echo "1. Edit backend/.env and add your Supabase credentials:"
echo "   - SUPABASE_URL=your_supabase_project_url"
echo "   - SUPABASE_KEY=your_supabase_anon_key"
echo ""
echo "2. Edit rasa-agent/.env and add your Supabase credentials:"
echo "   - SUPABASE_URL=your_supabase_project_url"
echo "   - SUPABASE_KEY=your_supabase_anon_key"
echo ""
echo "3. Run the Supabase schema:"
echo "   - Open Supabase SQL Editor"
echo "   - Copy database/schema.sql"
echo "   - Execute in SQL Editor"
echo ""
echo "4. Install Python 3.10 and Rasa dependencies (see SETUP_INSTRUCTIONS.md)"
echo ""
echo "✅ MiniMax API credentials are already configured!"
echo ""

