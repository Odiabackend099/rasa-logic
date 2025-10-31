#!/bin/bash
# Render build script - Memory Optimized for 512MB limit
set -e

echo "Starting memory-optimized build process..."

# The script is called from root directory, so we need to cd into rasa-agent
# But first check if we're already in rasa-agent directory
if [ ! -f "requirements.txt" ]; then
    echo "Changing to rasa-agent directory..."
    cd rasa-agent
fi

# Create and activate virtual environment
python3.10 -m venv venv
source venv/bin/activate

# Upgrade pip with no cache to save memory
pip install --upgrade --no-cache-dir pip setuptools wheel

# Install dependencies with no cache
echo "Installing dependencies with memory optimization..."
pip install --no-cache-dir -r requirements.txt
pip install --no-cache-dir -r actions/requirements.txt

# Clear pip cache to free memory
pip cache purge

# Set memory-efficient environment variables for training
export PYTHONHASHSEED=0
export TF_CPP_MIN_LOG_LEVEL=2
export CUDA_VISIBLE_DEVICES=""
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

# Train model only for server service with minimal config and memory optimization
if [ "$RASA_SERVICE_TYPE" != "actions" ]; then
    echo "Training Rasa model with minimal memory configuration..."
    # Use minimal config and single thread training
    rasa train --config config-minimal.yml --quiet --num-threads 1
    
    # Clean up training cache to free memory
    rm -rf .rasa/cache/tmp*
    rm -rf .rasa/cache/DIETClassifier*
    rm -rf .rasa/cache/ResponseSelector*
    rm -rf .rasa/cache/TEDPolicy*
    
    echo "Model training completed with memory optimization"
fi

echo "Build process completed successfully"

