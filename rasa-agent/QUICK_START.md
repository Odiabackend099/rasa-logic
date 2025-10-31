# Quick Start Guide

## Prerequisites Check

```bash
# Check Python version (must be 3.10.x)
python3.10 --version

# If not available, install (see SETUP_INSTRUCTIONS.md)
```

## Installation Steps

```bash
# 1. Navigate to rasa-agent directory
cd rasa-agent

# 2. Create and activate virtual environment (Python 3.10)
python3.10 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 3. Install dependencies
pip install --upgrade pip
pip install rasa rasa-sdk supabase python-dotenv

# 4. Install action server dependencies
cd actions
pip install -r requirements.txt
cd ..

# 5. Configure environment
cp env.example .env
# Edit .env with your Supabase credentials

# 6. Train the model
rasa train
```

## Running the Services

### Terminal 1: Rasa Server
```bash
cd rasa-agent
source venv/bin/activate
rasa run --enable-api --cors "*"
```

### Terminal 2: Action Server
```bash
cd rasa-agent
source venv/bin/activate
rasa run actions
```

### Terminal 3: Backend API
```bash
cd backend
npm start
```

## Testing

```bash
# Test chat endpoint
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "session_id": "test123"}'

# Test Rasa directly
cd rasa-agent
source venv/bin/activate
rasa shell
```

## Common Commands

```bash
# Validate configuration
rasa data validate

# Check model
rasa test

# Interactive shell
rasa shell

# Start server
rasa run --enable-api

# Start action server
rasa run actions

# Train model
rasa train

# Visualize stories
rasa visualize
```

