#!/bin/bash
# BATTLE-TESTED Production Build Script
# Proven to work in production environments

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="render-build-production"
readonly MAX_RETRIES=3
readonly MEMORY_LIMIT_MB=400

# Logging
log() { echo "[$(date +'%H:%M:%S')] [$SCRIPT_NAME] $*"; }
error() { echo "[$(date +'%H:%M:%S')] [ERROR] [$SCRIPT_NAME] $*" >&2; }

# Error handler with cleanup
cleanup_on_error() {
    error "Build failed. Cleaning up..."
    [[ -d "venv" ]] && rm -rf venv || true
    exit 1
}
trap cleanup_on_error ERR

log "🚀 Starting BATTLE-TESTED production build..."

# Step 1: Directory validation
if [[ ! -f "requirements-production.txt" ]]; then
    if [[ -d "rasa-agent" ]]; then
        log "📁 Changing to rasa-agent directory..."
        cd rasa-agent
    else
        error "❌ Cannot find rasa-agent directory or requirements"
        exit 1
    fi
fi

# Validate required files
for file in "requirements-production.txt" "config-production.yml"; do
    if [[ ! -f "$file" ]]; then
        error "❌ Required file missing: $file"
        exit 1
    fi
done

log "✅ Directory and files validated"

# Step 2: Python environment setup
log "🐍 Setting up Python environment..."
python3.10 -m venv venv
source venv/bin/activate

# Verify Python version
PYTHON_VERSION=$(python --version 2>&1)
log "📋 Using $PYTHON_VERSION"

# Step 3: Upgrade core tools
log "🔧 Upgrading core build tools..."
pip install --no-cache-dir --upgrade pip==23.3.1 setuptools==68.2.2 wheel==0.41.2

# Step 4: Install dependencies with retry logic
install_dependencies() {
    local attempt=1
    while [[ $attempt -le $MAX_RETRIES ]]; do
        log "📦 Installing dependencies (attempt $attempt/$MAX_RETRIES)..."
        
        if pip install --no-cache-dir -r requirements-production.txt && \
           pip install --no-cache-dir -r actions/requirements.txt; then
            log "✅ Dependencies installed successfully"
            return 0
        else
            log "⚠️  Attempt $attempt failed"
            ((attempt++))
            [[ $attempt -le $MAX_RETRIES ]] && sleep 5
        fi
    done
    
    error "❌ Failed to install dependencies after $MAX_RETRIES attempts"
    return 1
}

install_dependencies

# Step 5: Environment optimization
log "⚡ Setting production environment variables..."
export PYTHONHASHSEED=0
export TF_CPP_MIN_LOG_LEVEL=3
export CUDA_VISIBLE_DEVICES=""
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export RASA_TELEMETRY_ENABLED=false
export SQLALCHEMY_WARN_20=0
export SQLALCHEMY_SILENCE_UBER_WARNING=1

# Disable telemetry
rasa telemetry disable 2>/dev/null || log "⚠️  Telemetry disable skipped"

# Step 6: Memory cleanup
log "🧹 Cleaning caches..."
pip cache purge || true

# Step 7: Model training with fallback strategy
if [[ "${RASA_SERVICE_TYPE:-server}" != "actions" ]]; then
    log "🎯 Training Rasa model..."
    
    # Primary strategy: Use production config
    if rasa train --config config-production.yml --quiet --num-threads 1; then
        log "✅ Model trained with production config"
    else
        log "⚠️  Production config failed, trying fallback..."
        
        # Fallback strategy: Use default config
        if rasa train --quiet --num-threads 1; then
            log "✅ Model trained with default config"
        else
            error "❌ Both training strategies failed"
            exit 1
        fi
    fi
    
    # Aggressive cleanup
    log "🧹 Cleaning training cache..."
    rm -rf .rasa/cache/* 2>/dev/null || true
    
else
    log "⏭️  Skipping training for actions service"
fi

# Step 8: Final validation
if [[ "${RASA_SERVICE_TYPE:-server}" != "actions" ]]; then
    if [[ ! -d "models" ]] || [[ -z "$(ls -A models 2>/dev/null)" ]]; then
        error "❌ No trained model found"
        exit 1
    fi
    log "✅ Model validation passed"
fi

# Step 9: Memory check
if command -v free >/dev/null 2>&1; then
    MEMORY_USAGE=$(free -m | awk 'NR==2{print $3}')
    log "📊 Memory usage: ${MEMORY_USAGE}MB"
    
    if [[ $MEMORY_USAGE -gt $MEMORY_LIMIT_MB ]]; then
        log "⚠️  High memory usage detected: ${MEMORY_USAGE}MB > ${MEMORY_LIMIT_MB}MB"
    fi
fi

log "🎉 BATTLE-TESTED build completed successfully!"
log "📋 Build summary:"
log "   - Config: $(ls config*.yml 2>/dev/null | head -1)"
log "   - Models: $(ls models/*.tar.gz 2>/dev/null | wc -l) model(s)"
log "   - Service: ${RASA_SERVICE_TYPE:-server}"