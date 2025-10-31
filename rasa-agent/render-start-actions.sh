#!/bin/bash
# Render start script for Rasa action server
set -e

cd rasa-agent || cd .

# Activate virtual environment
if [ -d "venv" ]; then
  source venv/bin/activate
fi

# Start Rasa action server
echo "Starting Rasa action server on port $PORT..."
rasa run actions --port $PORT

