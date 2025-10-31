#!/bin/bash
# Update .env files with Supabase credentials

SUPABASE_URL="https://cgtvgvrqjxbptgnycqhv.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNndHZndnJxanhicHRnbnljcWh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4NjI3MjcsImV4cCI6MjA3NzQzODcyN30.bCmuqTCzeA6j72AjJPTYqBzwSrc36cy01vJ732j3MUU"

# Update rasa-agent/.env
if [ -f "rasa-agent/.env" ]; then
  sed -i '' "s|SUPABASE_URL=.*|SUPABASE_URL=$SUPABASE_URL|" rasa-agent/.env
  sed -i '' "s|SUPABASE_KEY=.*|SUPABASE_KEY=$SUPABASE_ANON_KEY|" rasa-agent/.env
  echo "✅ Updated rasa-agent/.env"
else
  echo "⚠️  rasa-agent/.env not found"
fi

# Update backend/.env
if [ -f "backend/.env" ]; then
  sed -i '' "s|SUPABASE_URL=.*|SUPABASE_URL=$SUPABASE_URL|" backend/.env
  sed -i '' "s|SUPABASE_KEY=.*|SUPABASE_KEY=$SUPABASE_ANON_KEY|" backend/.env
  echo "✅ Updated backend/.env"
else
  echo "⚠️  backend/.env not found"
fi

echo "✅ Supabase credentials configured!"
