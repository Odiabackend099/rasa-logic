#!/usr/bin/env bash
# Ultra-lightweight build for 512MB RAM limit
set -euo pipefail

echo "🚀 Ultra-lightweight Rasa build for 512MB RAM"

# Change to rasa-agent directory if needed
if [ ! -f "requirements-production.txt" ]; then
    echo "📁 Changing to rasa-agent directory..."
    cd rasa-agent
fi

# Create virtual environment
echo "🐍 Creating virtual environment..."
python3.10 -m venv venv
source venv/bin/activate

# Upgrade core tools with specific versions
echo "🔧 Installing core tools..."
pip install -U pip wheel setuptools==68.2.2

# Install ultra-light requirements (NO TensorFlow/JAX)
echo "📦 Installing ultra-light dependencies..."
pip install -r requirements-production.txt

# Set memory-efficient environment variables
export TF_CPP_MIN_LOG_LEVEL=3
export RASA_MAX_TRAINING_PROCESSES=1
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export RASA_TELEMETRY_ENABLED=false

# Train lightweight model at build time
echo "🎯 Training ultra-lightweight model..."
rasa train --config config-production.yml --fixed-model-name lightweight

echo "✅ Ultra-lightweight build completed!"
echo "📊 Model size:"
ls -lh models/lightweight.tar.gz || echo "Model file not found"