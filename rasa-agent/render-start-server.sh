#!/bin/bash
# Render start script for Rasa server
set -e

cd rasa-agent || cd .

# Activate virtual environment
if [ -d "venv" ]; then
  source venv/bin/activate
fi

# Start Rasa server
echo "Starting Rasa server on port $PORT..."
rasa run --enable-api --cors "*" --port $PORT

