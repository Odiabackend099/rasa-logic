#!/usr/bin/env python3
"""
Test the love conversation functionality with the trained Rasa model.
This demonstrates how the system responds to love-related questions.
"""

import requests
import json
import time

def test_rasa_love_conversation():
    """Test the love conversation with the Rasa model."""
    
    # Rasa webhook endpoint
    rasa_url = "http://localhost:5005/webhooks/rest/webhook"
    
    # Test messages
    test_messages = [
        "hello",
        "tell me softly what is the true meaning of love",
        "what does love mean to you?",
        "goodbye"
    ]
    
    print("💕 Testing Love Conversation with Rasa")
    print("=" * 50)
    
    for i, message in enumerate(test_messages, 1):
        print(f"\n🗣️  User ({i}): {message}")
        
        # Send message to Rasa
        payload = {
            "sender": "test_user",
            "message": message
        }
        
        try:
            response = requests.post(
                rasa_url,
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                responses = response.json()
                
                for j, bot_response in enumerate(responses, 1):
                    print(f"🤖 Bot ({i}.{j}): {bot_response.get('text', 'No text response')}")
                    
                    # Check for custom data (like TTS audio URL)
                    if 'custom' in bot_response:
                        custom_data = bot_response['custom']
                        if 'audio_url' in custom_data:
                            print(f"🎵 Audio URL: {custom_data['audio_url']}")
                            print(f"🎤 TTS Provider: {custom_data.get('tts_provider', 'unknown')}")
                        
            else:
                print(f"❌ Error: HTTP {response.status_code}")
                print(f"Response: {response.text}")
                
        except requests.exceptions.ConnectionError:
            print("❌ Connection error. Is Rasa running on localhost:5005?")
            print("💡 Start Rasa with: cd rasa-agent && rasa run --enable-api --cors '*'")
            break
        except requests.exceptions.Timeout:
            print("❌ Request timed out")
        except Exception as e:
            print(f"❌ Unexpected error: {str(e)}")
        
        # Small delay between messages
        time.sleep(1)
    
    print("\n" + "=" * 50)
    print("✅ Love conversation test completed!")

def show_love_response_preview():
    """Show a preview of the love response that would be converted to TTS."""
    
    love_response = """The true meaning of love whispers to us in the quiet moments between heartbeats. 

Love is not just an emotion, but a choice we make each day. It's the gentle touch that says "you matter" without words. It's seeing someone's flaws and choosing to stay, not despite them, but because they make that person beautifully human.

True love is patient. It doesn't rush or demand, but waits with open arms. It's the safety of knowing someone will catch you when you fall, and the courage to let yourself be vulnerable.

Love is found in small gestures - a warm cup of coffee on a cold morning, a listening ear after a difficult day, or simply sitting together in comfortable silence. It's choosing kindness when anger would be easier.

The deepest love starts with loving yourself - accepting your own imperfections and treating yourself with the same compassion you'd show a dear friend. Only then can you truly give love to others.

Love is not possession, but freedom. It's wanting the best for someone, even if that means letting them go. It's celebrating their dreams and supporting their journey, wherever it may lead.

In the end, love is the thread that connects all hearts, the light that guides us home, and the gentle reminder that we are never truly alone in this beautiful, complex world."""
    
    print("💕 Love Response Preview (for TTS conversion)")
    print("=" * 60)
    print(love_response)
    print("=" * 60)
    print(f"📊 Character count: {len(love_response)}")
    print(f"⏱️  Estimated TTS duration: ~60 seconds (at 0.9x speed)")
    print(f"🎵 Voice settings: female-soft, gentle delivery")

def main():
    """Main function."""
    
    print("🎯 Rasa Love TTS Demo")
    print("This demonstrates the 60-second soft TTS response about love.")
    print()
    
    # Show the response preview
    show_love_response_preview()
    
    print("\n" + "🚀 Testing with Rasa (requires running server)")
    
    # Test the conversation
    test_rasa_love_conversation()
    
    print("\n💡 To get the actual TTS audio:")
    print("1. Set your MiniMax API credentials")
    print("2. Start the Rasa actions server: rasa run actions")
    print("3. The ActionSendToMiniMax will generate the TTS audio")
    print("4. You'll receive an audio URL in the response")

if __name__ == "__main__":
    main()