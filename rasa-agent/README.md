# CallWaitingAI - Rasa Conversational Agent

Self-hosted Rasa Open Source conversational AI system to replace VAPI's conversation logic.

## Requirements

- Python 3.10 (3.11+ is not compatible with Rasa 3.x)
- Virtual environment (venv or Poetry)

## Setup Instructions

1. Create Python 3.10 virtual environment:
```bash
python3.10 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install --upgrade pip
pip install rasa rasa-sdk supabase
```

3. Initialize Rasa project:
```bash
rasa init --no-prompt
```

4. Train the model:
```bash
rasa train
```

5. Run Rasa server:
```bash
rasa run --enable-api --cors "*"
```

6. Run action server (in separate terminal):
```bash
rasa run actions
```

## Project Structure

- `data/` - Training data (NLU, stories, rules)
- `actions/` - Custom action server code
- `models/` - Trained Rasa models
- `config.yml` - Rasa configuration
- `domain.yml` - Domain definition (intents, entities, responses, actions)
- `endpoints.yml` - Endpoint configuration

## Integration

The Rasa server runs on `http://localhost:5005` and exposes:
- `/webhooks/rest/webhook` - REST API endpoint for chat
- `/model/predict` - Direct model prediction

The backend API (Node.js/Express) forwards requests to these endpoints.

