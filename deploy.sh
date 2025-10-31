#!/bin/bash
# Unified Deployment Script for CallWaitingAI
# Supports: local, docker, ec2, render deployments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="CallWaitingAI"
DEPLOYMENT_TYPE="${1:-local}"

# Logging functions
log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $*${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $*${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $*${NC}" >&2; }

# Help function
show_help() {
    cat << EOF
🚀 CallWaitingAI Unified Deployment Script

Usage: $0 [DEPLOYMENT_TYPE] [OPTIONS]

DEPLOYMENT TYPES:
  local     - Local development deployment
  docker    - Docker containerized deployment
  ec2       - AWS EC2 deployment
  render    - Render.com deployment
  help      - Show this help message

OPTIONS:
  --clean   - Clean build (remove cache, rebuild everything)
  --test    - Run tests after deployment
  --monitor - Start monitoring after deployment

EXAMPLES:
  $0 local              # Local development
  $0 docker --clean     # Clean Docker build
  $0 ec2 --test         # EC2 deployment with tests
  $0 render             # Deploy to Render

REQUIREMENTS:
  - Node.js 18+
  - Python 3.10
  - Docker (for docker/ec2 deployments)
  - Git (for render deployment)

EOF
}

# Check requirements
check_requirements() {
    log "🔍 Checking requirements..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js is required but not installed"
        exit 1
    fi
    
    local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 18 ]; then
        error "Node.js 18+ is required (found: $(node --version))"
        exit 1
    fi
    
    # Check Python
    if ! command -v python3.10 &> /dev/null; then
        warn "Python 3.10 not found, trying python3..."
        if ! command -v python3 &> /dev/null; then
            error "Python 3.10+ is required but not installed"
            exit 1
        fi
    fi
    
    # Check Docker for containerized deployments
    if [[ "$DEPLOYMENT_TYPE" == "docker" || "$DEPLOYMENT_TYPE" == "ec2" ]]; then
        if ! command -v docker &> /dev/null; then
            error "Docker is required for $DEPLOYMENT_TYPE deployment"
            exit 1
        fi
        
        if ! command -v docker-compose &> /dev/null; then
            error "Docker Compose is required for $DEPLOYMENT_TYPE deployment"
            exit 1
        fi
    fi
    
    log "✅ Requirements check passed"
}

# Setup environment
setup_environment() {
    log "🔧 Setting up environment..."
    
    # Create .env if it doesn't exist
    if [ ! -f ".env" ]; then
        log "📝 Creating .env from template..."
        cp .env.example .env
        warn "Please edit .env file with your configuration before proceeding"
        
        if command -v code &> /dev/null; then
            log "Opening .env in VS Code..."
            code .env
        elif command -v nano &> /dev/null; then
            log "Opening .env in nano..."
            nano .env
        else
            log "Please edit .env file manually"
        fi
        
        read -p "Press Enter after configuring .env file..."
    fi
    
    # Copy environment to services
    if [ -f ".env" ]; then
        log "📋 Copying environment to services..."
        cp .env backend/.env 2>/dev/null || true
        cp .env rasa-agent/.env 2>/dev/null || true
    fi
}

# Clean build artifacts
clean_build() {
    log "🧹 Cleaning build artifacts..."
    
    # Clean Docker
    if command -v docker &> /dev/null; then
        docker system prune -f || true
        docker volume prune -f || true
    fi
    
    # Clean Node modules
    rm -rf backend/node_modules || true
    
    # Clean Rasa cache and models
    rm -rf rasa-agent/.rasa/cache/* || true
    rm -rf rasa-agent/models/* || true
    
    # Clean Python cache
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete 2>/dev/null || true
    
    log "✅ Cleanup completed"
}

# Local deployment
deploy_local() {
    log "🏠 Starting local deployment..."
    
    # Install dependencies
    log "📦 Installing dependencies..."
    npm run install:all
    
    # Train Rasa model
    log "🎯 Training Rasa model..."
    npm run train
    
    # Start services
    log "🚀 Starting services..."
    echo "Starting backend server..."
    npm run start:backend &
    BACKEND_PID=$!
    
    echo "Starting Rasa server..."
    npm run start:rasa &
    RASA_PID=$!
    
    echo "Starting Rasa actions..."
    npm run start:actions &
    ACTIONS_PID=$!
    
    # Wait for services to start
    sleep 10
    
    # Health check
    log "🔍 Performing health checks..."
    if npm run health; then
        log "✅ Local deployment successful!"
        log "🌐 Backend: http://localhost:3000"
        log "🤖 Rasa: http://localhost:5005"
        log "⚡ Actions: http://localhost:5055"
        
        log "Press Ctrl+C to stop all services"
        wait
    else
        error "Health check failed"
        kill $BACKEND_PID $RASA_PID $ACTIONS_PID 2>/dev/null || true
        exit 1
    fi
}

# Docker deployment
deploy_docker() {
    log "🐳 Starting Docker deployment..."
    
    # Build and start containers
    log "🏗️  Building containers..."
    npm run docker:build
    
    log "🚀 Starting containers..."
    npm run docker:up
    
    # Wait for containers to be ready
    log "⏳ Waiting for containers to be ready..."
    sleep 30
    
    # Health check
    log "🔍 Performing health checks..."
    if curl -f http://localhost/health &>/dev/null; then
        log "✅ Docker deployment successful!"
        log "🌐 Application: http://localhost"
        log "📊 Monitor: docker-compose logs -f"
    else
        error "Health check failed"
        npm run docker:logs
        exit 1
    fi
}

# EC2 deployment
deploy_ec2() {
    log "☁️  Starting EC2 deployment..."
    
    if [ ! -f "deployment/ec2/deploy.sh" ]; then
        error "EC2 deployment scripts not found"
        exit 1
    fi
    
    log "🚀 Running EC2 deployment script..."
    chmod +x deployment/ec2/deploy.sh
    ./deployment/ec2/deploy.sh
}

# Render deployment
deploy_render() {
    log "🌐 Starting Render deployment..."
    
    # Check if we're in a git repository
    if [ ! -d ".git" ]; then
        error "Not in a git repository. Render deployment requires git."
        exit 1
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        warn "You have uncommitted changes. Committing them now..."
        git add .
        git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    
    log "📤 Pushing to Render..."
    git push origin main
    
    log "✅ Render deployment initiated!"
    log "🌐 Check your Render dashboard for deployment status"
}

# Run tests
run_tests() {
    log "🧪 Running tests..."
    
    if npm run test; then
        log "✅ All tests passed!"
    else
        error "Tests failed"
        exit 1
    fi
}

# Start monitoring
start_monitoring() {
    log "📊 Starting monitoring..."
    
    case "$DEPLOYMENT_TYPE" in
        "local")
            log "📈 Local monitoring - check terminal outputs"
            ;;
        "docker")
            log "📈 Docker monitoring:"
            npm run monitor
            ;;
        "ec2")
            log "📈 EC2 monitoring - check deployment/ec2/README.md"
            ;;
        "render")
            log "📈 Render monitoring - check Render dashboard"
            ;;
    esac
}

# Main deployment function
main() {
    log "🚀 $PROJECT_NAME Unified Deployment"
    log "📋 Deployment Type: $DEPLOYMENT_TYPE"
    
    # Parse options
    CLEAN_BUILD=false
    RUN_TESTS=false
    START_MONITOR=false
    
    for arg in "$@"; do
        case $arg in
            --clean)
                CLEAN_BUILD=true
                ;;
            --test)
                RUN_TESTS=true
                ;;
            --monitor)
                START_MONITOR=true
                ;;
        esac
    done
    
    # Show help
    if [[ "$DEPLOYMENT_TYPE" == "help" ]]; then
        show_help
        exit 0
    fi
    
    # Validate deployment type
    case "$DEPLOYMENT_TYPE" in
        "local"|"docker"|"ec2"|"render")
            ;;
        *)
            error "Invalid deployment type: $DEPLOYMENT_TYPE"
            show_help
            exit 1
            ;;
    esac
    
    # Check requirements
    check_requirements
    
    # Clean build if requested
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build
    fi
    
    # Setup environment
    setup_environment
    
    # Deploy based on type
    case "$DEPLOYMENT_TYPE" in
        "local")
            deploy_local
            ;;
        "docker")
            deploy_docker
            ;;
        "ec2")
            deploy_ec2
            ;;
        "render")
            deploy_render
            ;;
    esac
    
    # Run tests if requested
    if [ "$RUN_TESTS" = true ]; then
        run_tests
    fi
    
    # Start monitoring if requested
    if [ "$START_MONITOR" = true ]; then
        start_monitoring
    fi
    
    log "🎉 Deployment completed successfully!"
}

# Trap Ctrl+C and cleanup
trap 'log "🛑 Deployment interrupted"; exit 130' INT

# Run main function
main "$@"