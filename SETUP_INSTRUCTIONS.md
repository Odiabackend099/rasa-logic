# Setup Instructions

Follow these steps to complete the setup and installation.

## Step 1: Install Python 3.10

**CRITICAL**: Rasa requires Python 3.10 (Python 3.11+ is NOT compatible).

### macOS (Development)
See `PYTHON_VERSION_NOTE.md` for detailed instructions.

### Quick Option (macOS with Homebrew):
```bash
# Install pyenv if not installed
brew install pyenv

# Install Python 3.10
pyenv install 3.10.13

# Set for this project
cd "/Users/odiadev/Desktop/rasa open source/rasa-agent"
pyenv local 3.10.13

# Create venv
python3.10 -m venv venv
source venv/bin/activate
```

## Step 2: Install Rasa Dependencies

Once Python 3.10 is available:

```bash
cd rasa-agent
source venv/bin/activate  # or: . venv/bin/activate

# Install Rasa and dependencies
pip install --upgrade pip
pip install rasa rasa-sdk supabase python-dotenv

# Install action server dependencies
cd actions
pip install -r requirements.txt
cd ..
```

## Step 3: Configure Environment Variables

### 3.1 Rasa Agent Environment

Create/edit `rasa-agent/.env`:

```bash
cd rasa-agent
cp env.example .env
```

Edit `.env` and add your Supabase credentials:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
```

### 3.2 Backend Environment

The backend `.env` file has been created with MiniMax credentials already configured. You still need to add:

1. **Supabase credentials**:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_KEY=your_supabase_anon_key
```

2. **MiniMax API URL** (if different from default):
```
MINIMAX_API_URL=https://api.minimax.chat/v1
```

The following are already configured:
- ✅ `MINIMAX_API_KEY`
- ✅ `MINIMAX_GROUP_ID`
- ✅ `MINIMAX_MODEL=speech-02-hd`

## Step 4: Setup Supabase Database

### 4.1 Create Supabase Project

1. Go to https://supabase.com
2. Create a new project
3. Note your project URL and anon key

### 4.2 Run Database Schema

1. Open Supabase SQL Editor
2. Copy contents of `database/schema.sql`
3. Paste and execute in SQL Editor

This creates:
- `call_logs` table
- `leads` table
- `conversations` table
- `handoffs` table
- All indexes and RLS policies

### 4.3 Update Environment Variables

Update both `.env` files with your Supabase credentials:
- `rasa-agent/.env`
- `backend/.env`

## Step 5: Train Rasa Model

Once Python 3.10 is installed and dependencies are set:

```bash
cd rasa-agent
source venv/bin/activate
rasa train
```

This will:
- Validate configuration files
- Train NLU model
- Train dialogue model
- Save model to `models/` directory

Training may take 5-10 minutes depending on hardware.

## Step 6: Test Installation

### 6.1 Start Rasa Server

Terminal 1:
```bash
cd rasa-agent
source venv/bin/activate
rasa run --enable-api --cors "*"
```

Server should start on `http://localhost:5005`

### 6.2 Start Action Server

Terminal 2:
```bash
cd rasa-agent
source venv/bin/activate
rasa run actions
```

Action server should start on `http://localhost:5055`

### 6.3 Start Backend API

Terminal 3:
```bash
cd backend
npm start
# Or for development with auto-reload:
npm run dev
```

Backend should start on `http://localhost:3000`

### 6.4 Test Chat Endpoint

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "session_id": "test123"}'
```

Expected response:
```json
{
  "session_id": "test123",
  "text": "Hello! Welcome to CallWaitingAI...",
  "intent": "greet",
  "confidence": 0.95
}
```

### 6.5 Test Rasa Directly

```bash
cd rasa-agent
source venv/bin/activate
rasa shell
```

Type "Hello" and see the bot respond.

## Step 7: Verification Checklist

- [ ] Python 3.10 installed and active
- [ ] Rasa installed (`rasa --version`)
- [ ] Action server dependencies installed
- [ ] Backend dependencies installed (`npm install` completed)
- [ ] Supabase project created
- [ ] Database schema executed
- [ ] Environment variables configured in both `.env` files
- [ ] Rasa model trained (`rasa train` completed)
- [ ] All three services start without errors
- [ ] Chat endpoint responds correctly

## Troubleshooting

### Python Version Issues
- Verify Python version: `python --version` (should be 3.10.x)
- If wrong version, activate correct venv or use `pyenv local 3.10.13`

### Rasa Training Errors
- Check `config.yml` syntax
- Validate `domain.yml` structure
- Review training data in `data/` directory

### Backend Connection Errors
- Verify Rasa server is running on port 5005
- Check `RASA_SERVER_URL` in backend `.env`
- Test Rasa endpoint: `curl http://localhost:5005/status`

### Supabase Connection Errors
- Verify credentials in `.env` files
- Test connection in Supabase dashboard
- Check RLS policies allow service role access

## Next Steps

Once setup is complete, proceed to deployment:
- See `DEPLOYMENT.md` for AWS EC2 deployment
- Configure production environment variables
- Set up SSL certificates
- Configure monitoring and logging

