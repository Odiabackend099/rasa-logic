#!/usr/bin/env bash
# Ultra-lightweight Rasa server for 512MB RAM
set -euo pipefail

echo "🚀 Starting ultra-lightweight Rasa server"

# Change to rasa-agent directory if needed
if [ ! -f "requirements-production.txt" ]; then
    echo "📁 Changing to rasa-agent directory..."
    cd rasa-agent
fi

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Set ultra-light environment variables
export PORT="${PORT:-10000}"
export TF_CPP_MIN_LOG_LEVEL=3
export RASA_MAX_TRAINING_PROCESSES=1
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export RASA_TELEMETRY_ENABLED=false

echo "📊 Environment:"
echo "   - Port: $PORT"
echo "   - Threads: 1 (OMP/OPENBLAS/MKL)"
echo "   - Workers: 1"
echo "   - Model: lightweight.tar.gz"

# Ensure we have the lightweight model
if [ ! -f models/lightweight.tar.gz ]; then
    echo "⚠️  Lightweight model not found, training now..."
    rasa train --config config-production.yml --fixed-model-name lightweight
fi

echo "🎯 Starting Rasa server with ultra-light configuration..."

# Start with minimal resources
exec rasa run \
    --enable-api \
    --cors "*" \
    --port "$PORT" \
    --model models/lightweight.tar.gz \
    --log-level INFO \
    --debug false \
    --workers 1

