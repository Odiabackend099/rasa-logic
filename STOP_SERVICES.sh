#!/bin/bash
# Script to stop all CallWaitingAI services

echo "Stopping CallWaitingAI services..."

# Stop Rasa Server
if [ -f /tmp/rasa_server.pid ]; then
    RASA_PID=$(cat /tmp/rasa_server.pid)
    if kill -0 $RASA_PID 2>/dev/null; then
        kill $RASA_PID
        echo "✅ Stopped Rasa server (PID: $RASA_PID)"
    fi
    rm /tmp/rasa_server.pid
fi

# Stop Action Server
if [ -f /tmp/rasa_actions.pid ]; then
    ACTIONS_PID=$(cat /tmp/rasa_actions.pid)
    if kill -0 $ACTIONS_PID 2>/dev/null; then
        kill $ACTIONS_PID
        echo "✅ Stopped Action server (PID: $ACTIONS_PID)"
    fi
    rm /tmp/rasa_actions.pid
fi

# Stop Backend API
if [ -f /tmp/backend_api.pid ]; then
    BACKEND_PID=$(cat /tmp/backend_api.pid)
    if kill -0 $BACKEND_PID 2>/dev/null; then
        kill $BACKEND_PID
        echo "✅ Stopped Backend API (PID: $BACKEND_PID)"
    fi
    rm /tmp/backend_api.pid
fi

# Also kill any processes on these ports
lsof -ti:5005 | xargs kill -9 2>/dev/null
lsof -ti:5055 | xargs kill -9 2>/dev/null
lsof -ti:3000 | xargs kill -9 2>/dev/null

echo "✅ All services stopped"

