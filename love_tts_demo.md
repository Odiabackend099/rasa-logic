# 💕 Love TTS Demo - 60 Second Soft Response

## What I've Created

I've implemented a beautiful 60-second TTS response about the true meaning of love that integrates with your Rasa system. Here's what's been added:

### 🎯 **The Response Text (1,398 characters - ~60 seconds)**

```
The true meaning of love... it whispers to us in the quiet moments between heartbeats. 

Love is not just an emotion, but a choice we make each day. It's the gentle touch that says 
"you matter" without words. It's seeing someone's flaws and choosing to stay, not despite them, 
but because they make that person beautifully human.

True love is patient. It doesn't rush or demand, but waits with open arms. It's the safety 
of knowing someone will catch you when you fall, and the courage to let yourself be vulnerable.

Love is found in small gestures - a warm cup of coffee on a cold morning, a listening ear 
after a difficult day, or simply sitting together in comfortable silence. It's choosing 
kindness when anger would be easier.

The deepest love starts with loving yourself - accepting your own imperfections and treating 
yourself with the same compassion you'd show a dear friend. Only then can you truly give 
love to others.

Love is not possession, but freedom. It's wanting the best for someone, even if that means 
letting them go. It's celebrating their dreams and supporting their journey, wherever it 
may lead.

In the end, love is the thread that connects all hearts, the light that guides us home, 
and the gentle reminder that we are never truly alone in this beautiful, complex world.
```

### 🎵 **Voice Settings for Soft Delivery**

```json
{
  "voice_id": "female-soft",
  "speed": 0.9,     // Slightly slower for gentle delivery
  "vol": 0.8,       // Moderate volume for intimacy
  "pitch": 0        // Natural pitch
}
```

## 🚀 **What I've Implemented**

### 1. **NLU Training Data** (`data/nlu.yml`)
Added new intent `ask_about_love` with examples:
- "tell me about love"
- "what is the true meaning of love?"
- "tell me softly what is the true meaning of love"
- "what does love mean to you?"
- And more variations...

### 2. **Story Flow** (`data/stories.yml`)
```yaml
- story: ask about love with TTS
  steps:
  - intent: ask_about_love
  - action: action_send_to_minimax
```

### 3. **Domain Configuration** (`domain.yml`)
Added the `ask_about_love` intent to the domain.

### 4. **Enhanced Action** (`actions/actions.py`)
Updated `ActionSendToMiniMax` to:
- Detect love-related questions
- Use the beautiful 60-second response
- Apply soft voice settings
- Generate TTS with MiniMax API

## 🎯 **How to Use**

### Option 1: Direct API Test
```bash
# Set your MiniMax credentials
export MINIMAX_API_KEY="your-api-key"
export MINIMAX_GROUP_ID="your-group-id"
export MINIMAX_API_URL="https://api.minimax.io/v1"
export MINIMAX_MODEL="speech-02-hd"

# Run the test script
python3 test_love_tts.py
```

### Option 2: Through Rasa Chat
1. Train the model: `rasa train`
2. Start the action server: `rasa run actions`
3. Start Rasa: `rasa shell`
4. Ask: "tell me softly what is the true meaning of love"

### Option 3: Through API Call
```bash
curl -X POST http://localhost:5005/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "sender": "user",
    "message": "tell me softly what is the true meaning of love"
  }'
```

## 🎉 **Expected Result**

When triggered, the system will:
1. ✅ Recognize the love-related intent
2. ✅ Generate the beautiful 60-second response
3. ✅ Use soft female voice with gentle settings
4. ✅ Return an audio URL for the TTS
5. ✅ Provide approximately 60 seconds of soft, meaningful content

## 🔧 **Next Steps**

To make this work in production:
1. Set your MiniMax API credentials in the environment
2. Train the Rasa model with the new data
3. Deploy the updated actions server
4. Test with the love-related questions

The response is crafted to be deeply meaningful, gentle, and approximately 60 seconds when spoken at the configured pace (0.9x speed with soft delivery).

---

*"Love is the thread that connects all hearts, the light that guides us home, and the gentle reminder that we are never truly alone in this beautiful, complex world."* 💕