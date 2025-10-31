#!/bin/bash
# Render build script - Memory Optimized for 512MB limit
# Senior Engineer Review: Enhanced with comprehensive error handling and security

set -euo pipefail  # Enhanced error handling: exit on error, undefined vars, pipe failures

# Build configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly BUILD_START_TIME=$(date +%s)

# Logging functions
log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] [$SCRIPT_NAME] $*"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] [$SCRIPT_NAME] $*" >&2
}

log_warn() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] [$SCRIPT_NAME] $*" >&2
}

# Error trap handler
error_handler() {
    local exit_code=$?
    local line_number=$1
    log_error "Build failed at line $line_number with exit code $exit_code"
    log_error "Command: $BASH_COMMAND"
    
    # Cleanup on error
    if [[ -d "venv" ]]; then
        log_info "Cleaning up virtual environment due to error..."
        rm -rf venv || true
    fi
    
    exit $exit_code
}

# Set error trap
trap 'error_handler $LINENO' ERR

log_info "Starting memory-optimized build process..."
log_info "Build environment: Python $(python3.10 --version 2>/dev/null || echo 'Unknown'), $(uname -s) $(uname -m)"

# Input validation and security
if [[ -n "${RASA_SERVICE_TYPE:-}" ]]; then
    case "$RASA_SERVICE_TYPE" in
        "server"|"actions"|"")
            log_info "Service type: ${RASA_SERVICE_TYPE:-server}"
            ;;
        *)
            log_error "Invalid RASA_SERVICE_TYPE: $RASA_SERVICE_TYPE. Must be 'server' or 'actions'"
            exit 1
            ;;
    esac
fi

# Enhanced directory detection with validation
detect_and_change_directory() {
    local target_dir="rasa-agent"
    
    if [[ -f "requirements.txt" && -f "config-minimal.yml" ]]; then
        log_info "Already in rasa-agent directory"
        return 0
    fi
    
    if [[ -d "$target_dir" ]]; then
        log_info "Changing to $target_dir directory..."
        cd "$target_dir" || {
            log_error "Failed to change to $target_dir directory"
            exit 1
        }
        
        # Validate we're in the right place
        if [[ ! -f "requirements.txt" ]]; then
            log_error "requirements.txt not found in $target_dir directory"
            exit 1
        fi
        
        log_info "Successfully changed to $(pwd)"
    else
        log_error "Directory $target_dir not found"
        exit 1
    fi
}

# Memory and performance monitoring
monitor_memory() {
    if command -v free >/dev/null 2>&1; then
        local mem_info=$(free -m | awk 'NR==2{printf "Memory: %s/%sMB (%.2f%%)", $3,$2,$3*100/$2}')
        log_info "$mem_info"
    fi
}

# Enhanced dependency installation with retry logic
install_dependencies_with_retry() {
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        log_info "Installing dependencies (attempt $((retry_count + 1))/$max_retries)..."
        
        if pip install --no-cache-dir -r requirements.txt && \
           pip install --no-cache-dir -r actions/requirements.txt; then
            log_info "Dependencies installed successfully"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [[ $retry_count -lt $max_retries ]]; then
                log_warn "Dependency installation failed, retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done
    
    log_error "Failed to install dependencies after $max_retries attempts"
    return 1
}

# Main build process
main() {
    # Step 1: Directory setup
    detect_and_change_directory
    
    # Step 2: Virtual environment setup
    log_info "Creating Python virtual environment..."
    python3.10 -m venv venv || {
        log_error "Failed to create virtual environment"
        exit 1
    }
    
    log_info "Activating virtual environment..."
    source venv/bin/activate || {
        log_error "Failed to activate virtual environment"
        exit 1
    }
    
    # Step 3: Memory monitoring
    monitor_memory
    
    # Step 4: Pip upgrade
    log_info "Upgrading pip and build tools..."
    pip install --upgrade --no-cache-dir pip setuptools wheel || {
        log_error "Failed to upgrade pip and build tools"
        exit 1
    }
    
    # Step 5: Dependency installation
    install_dependencies_with_retry
    
    # Step 6: Disable telemetry (after Rasa is installed)
    log_info "Disabling Rasa telemetry..."
    rasa telemetry disable 2>/dev/null || {
        log_warn "Could not disable telemetry (may not be available yet)"
    }
    
    # Step 7: Cache cleanup
    log_info "Clearing pip cache to free memory..."
    pip cache purge || log_warn "Could not purge pip cache"
    
    # Step 8: Set memory-efficient environment variables
    log_info "Setting memory-efficient environment variables..."
    export PYTHONHASHSEED=0
    export TF_CPP_MIN_LOG_LEVEL=2
    export CUDA_VISIBLE_DEVICES=""
    export OMP_NUM_THREADS=1
    export OPENBLAS_NUM_THREADS=1
    export RASA_TELEMETRY_ENABLED=false
    
    # Step 9: Model training (server only)
    if [[ "${RASA_SERVICE_TYPE:-server}" != "actions" ]]; then
        log_info "Training Rasa model with minimal memory configuration..."
        monitor_memory
        
        # Validate config file exists
        if [[ ! -f "config-minimal.yml" ]]; then
            log_error "config-minimal.yml not found"
            exit 1
        fi
        
        # Train with comprehensive error handling
        if rasa train --config config-minimal.yml --quiet --num-threads 1; then
            log_info "Model training completed successfully"
        else
            log_error "Model training failed"
            exit 1
        fi
        
        # Aggressive cache cleanup
        log_info "Cleaning up training cache to free memory..."
        rm -rf .rasa/cache/tmp* .rasa/cache/DIETClassifier* .rasa/cache/ResponseSelector* .rasa/cache/TEDPolicy* 2>/dev/null || true
        
        monitor_memory
    else
        log_info "Skipping model training for actions service"
    fi
    
    # Step 10: Build completion
    local build_duration=$(($(date +%s) - BUILD_START_TIME))
    log_info "Build process completed successfully in ${build_duration}s"
    
    # Final memory check
    monitor_memory
}

# Execute main function
main "$@"

