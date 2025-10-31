#!/bin/bash
# Render build script for Rasa services
set -e

echo "Setting up Python environment..."
python3.10 -m venv venv
source venv/bin/activate

echo "Upgrading pip..."
pip install --upgrade pip

echo "Installing Rasa dependencies..."
pip install -r requirements.txt

echo "Installing action server dependencies..."
pip install -r actions/requirements.txt

# Only train if this is the rasa-server (not actions server)
if [ "$RASA_SERVICE_TYPE" != "actions" ]; then
  echo "Training Rasa model..."
  rasa train --quiet
  echo "✅ Rasa model trained"
fi

echo "✅ Rasa build complete"

