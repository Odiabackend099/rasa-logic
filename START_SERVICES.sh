#!/bin/bash
# Script to start all CallWaitingAI services

echo "=================================="
echo "Starting CallWaitingAI Services"
echo "=================================="
echo ""

# Activate pyenv if available
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}⚠️  Port $1 is already in use${NC}"
        return 1
    fi
    return 0
}

# Start Rasa Server
echo "Starting Rasa Server..."
cd "$BASE_DIR/rasa-agent"
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please set up Python 3.10 first."
    exit 1
fi

source venv/bin/activate

if check_port 5005; then
    rasa run --enable-api --cors "*" --port 5005 &
    RASA_PID=$!
    echo -e "${GREEN}✅ Rasa server started (PID: $RASA_PID) on http://localhost:5005${NC}"
    echo $RASA_PID > /tmp/rasa_server.pid
else
    echo "❌ Cannot start Rasa server - port 5005 is in use"
fi

sleep 2

# Start Action Server
echo ""
echo "Starting Action Server..."
if check_port 5055; then
    rasa run actions --port 5055 &
    ACTIONS_PID=$!
    echo -e "${GREEN}✅ Action server started (PID: $ACTIONS_PID) on http://localhost:5055${NC}"
    echo $ACTIONS_PID > /tmp/rasa_actions.pid
else
    echo "❌ Cannot start Action server - port 5055 is in use"
fi

sleep 2

# Start Backend API
echo ""
echo "Starting Backend API..."
cd "$BASE_DIR/backend"

if check_port 3000; then
    npm start &
    BACKEND_PID=$!
    echo -e "${GREEN}✅ Backend API started (PID: $BACKEND_PID) on http://localhost:3000${NC}"
    echo $BACKEND_PID > /tmp/backend_api.pid
else
    echo "❌ Cannot start Backend API - port 3000 is in use"
fi

echo ""
echo "=================================="
echo "All services started!"
echo "=================================="
echo ""
echo "Services:"
echo "  - Rasa Server: http://localhost:5005"
echo "  - Action Server: http://localhost:5055"
echo "  - Backend API: http://localhost:3000"
echo ""
echo "To stop all services:"
echo "  ./STOP_SERVICES.sh"
echo ""
echo "To view logs:"
echo "  tail -f /tmp/rasa_server.log"
echo "  tail -f /tmp/rasa_actions.log"
echo "  tail -f /tmp/backend_api.log"
echo ""

