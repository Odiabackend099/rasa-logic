#!/bin/bash
# Render start script for Rasa server - Memory Optimized
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
export TF_CPP_MIN_LOG_LEVEL=2
export CUDA_VISIBLE_DEVICES=""
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

# Start Rasa server with memory optimization
echo "Starting Rasa server on port $PORT with memory optimization..."
rasa run --enable-api --cors "*" --port $PORT --endpoints endpoints.yml

