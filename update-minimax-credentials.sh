#!/bin/bash
# Update MiniMax credentials with correct endpoint and new API key

MINIMAX_API_KEY="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJHcm91cE5hbWUiOiJPRElBIGJhY2tlbmQiLCJVc2VyTmFtZSI6Ik9ESUEgYmFja2VuZCIsIkFjY291bnQiOiIiLCJTdWJqZWN0SUQiOiIxOTMzNTEwOTg4MDAzMjgzNzUxIiwiUGhvbmUiOiIiLCJHcm91cElEIjoiMTkzMzUxMDk4Nzk5NDg5NTE0MyIsIlBhZ2VOYW1lIjoiIiwiTWFpbCI6Im9kaWFiYWNrZW5kQGdtYWlsLmNvbSIsIkNyZWF0ZVRpbWUiOiIyMDI1LTEwLTMxIDA3OjU5OjU2IiwiVG9rZW5UeXBlIjoxLCJpc3MiOiJtaW5pbWF4In0.sbtLDocbhzFgUz9ZPpjscpM5iQA0_ZuJEqQXQ3fw3gd0Rfd6iC1XIDXaeCh1PbO3S2v-UsxPu5eJGAlDEHYcLzTQgd-ZXCvpW2C5HKVN2Yw1fwdYlzhXcgaCGdFn9ZeAySI9bj-Vs0SN7DubmmU4PVeNs3RYfVuu1AyH2U_A4PDeJEFDEDpFje2RC4fertBMS6Jj9lvXBF5etDCDfzgqtQVSdXKi97Vqx7soPF4pbBxB67rh9O3TSXkkC8QXYr6hjOhnyw-zy06ixg2Xu5CLIuqBTObQEQv5VpfzCkvqZhjpfrxvH3Epif07OMbCWJP8lQ36un0RuAdyZXLBfmO8Fg"
MINIMAX_GROUP_ID="1933510987994895143"
MINIMAX_MODEL="speech-02-hd"
MINIMAX_API_URL="https://api.minimax.io/v1"

# Update backend/.env
if [ -f "backend/.env" ]; then
  sed -i '' "s|MINIMAX_API_URL=.*|MINIMAX_API_URL=$MINIMAX_API_URL|" backend/.env
  sed -i '' "s|MINIMAX_API_KEY=.*|MINIMAX_API_KEY=$MINIMAX_API_KEY|" backend/.env
  sed -i '' "s|MINIMAX_GROUP_ID=.*|MINIMAX_GROUP_ID=$MINIMAX_GROUP_ID|" backend/.env
  sed -i '' "s|MINIMAX_MODEL=.*|MINIMAX_MODEL=$MINIMAX_MODEL|" backend/.env
  echo "✅ Updated backend/.env with correct MiniMax credentials"
else
  echo "⚠️  backend/.env not found"
fi

echo "✅ MiniMax credentials updated!"
echo "   API URL: $MINIMAX_API_URL"
echo "   Endpoint: /t2a_v2 (TTS)"
