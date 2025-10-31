#!/bin/bash
# Render start script for Rasa action server - Memory Optimized
set -e

# The script is called from root directory, so we need to cd into rasa-agent
# But first check if we're already in rasa-agent directory
if [ ! -f "requirements.txt" ]; then
    echo "Changing to rasa-agent directory..."
    cd rasa-agent
fi

# Activate virtual environment
if [ -d "venv" ]; then
  source venv/bin/activate
fi

# Set memory-efficient environment variables
export PYTHONHASHSEED=0
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

# Start Rasa action server with memory optimization
echo "Starting Rasa action server on port $PORT with memory optimization..."
rasa run actions --port $PORT

