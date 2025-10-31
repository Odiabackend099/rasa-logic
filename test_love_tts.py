#!/usr/bin/env python3
"""
Test script to generate a 60-second TTS response about the true meaning of love
using the MiniMax TTS integration from the Rasa actions.
"""

import os
import sys
import requests
import json
from datetime import datetime

# Add the actions directory to the path
sys.path.append('rasa-agent/actions')

def create_love_response():
    """Create a beautiful, soft 60-second response about the true meaning of love."""
    
    love_text = """
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
    """
    
    return love_text.strip()

def test_minimax_tts(text):
    """Test the MiniMax TTS API with the love response."""
    
    # Load environment variables (you'll need to set these)
    api_url = os.getenv('MINIMAX_API_URL', 'https://api.minimax.io/v1')
    api_key = os.getenv('MINIMAX_API_KEY')
    group_id = os.getenv('MINIMAX_GROUP_ID')
    model = os.getenv('MINIMAX_MODEL', 'speech-02-hd')
    
    if not all([api_key, group_id]):
        print("❌ Missing MiniMax credentials. Please set:")
        print("   - MINIMAX_API_KEY")
        print("   - MINIMAX_GROUP_ID")
        print("   - MINIMAX_API_URL (optional)")
        print("   - MINIMAX_MODEL (optional)")
        return None
    
    print(f"🎵 Generating TTS for {len(text)} characters...")
    print(f"📝 Text preview: {text[:100]}...")
    
    # Prepare the request
    headers = {
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    
    payload = {
        'group_id': group_id,
        'model': model,
        'text': text,
        'voice_setting': {
            'voice_id': 'female-soft',  # Soft female voice for the love theme
            'speed': 0.9,  # Slightly slower for a gentle delivery
            'vol': 0.8,    # Moderate volume
            'pitch': 0     # Natural pitch
        }
    }
    
    try:
        print("🚀 Calling MiniMax TTS API...")
        response = requests.post(
            f"{api_url}/text_to_speech",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        response.raise_for_status()
        result = response.json()
        
        if 'audio_url' in result:
            audio_url = result['audio_url']
            print(f"✅ TTS generated successfully!")
            print(f"🎧 Audio URL: {audio_url}")
            print(f"⏱️  Estimated duration: ~60 seconds")
            
            # Save the result
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            result_file = f"love_tts_result_{timestamp}.json"
            
            with open(result_file, 'w') as f:
                json.dump({
                    'text': text,
                    'audio_url': audio_url,
                    'generated_at': timestamp,
                    'provider': 'minimax',
                    'voice_settings': payload['voice_setting']
                }, f, indent=2)
            
            print(f"💾 Result saved to: {result_file}")
            return audio_url
            
        else:
            print("❌ No audio URL in response")
            print(f"Response: {result}")
            return None
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out")
        return None
    except requests.exceptions.ConnectionError:
        print("❌ Connection error")
        return None
    except requests.exceptions.HTTPError as e:
        print(f"❌ HTTP error: {e.response.status_code}")
        print(f"Response: {e.response.text}")
        return None
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return None

def main():
    """Main function to generate the love TTS response."""
    
    print("💕 Generating a soft TTS response about the true meaning of love...")
    print("=" * 60)
    
    # Create the love response
    love_text = create_love_response()
    
    print(f"📝 Generated text ({len(love_text)} characters):")
    print("-" * 40)
    print(love_text)
    print("-" * 40)
    
    # Test the TTS generation
    audio_url = test_minimax_tts(love_text)
    
    if audio_url:
        print("\n🎉 Success! Your soft TTS response about love is ready.")
        print(f"🎧 You can listen to it at: {audio_url}")
        print("\n💡 To use this in your Rasa bot:")
        print("   1. Add this text to your training data")
        print("   2. Create an intent for love-related questions")
        print("   3. Use the ActionSendToMiniMax action to generate TTS")
    else:
        print("\n❌ TTS generation failed. Please check your MiniMax credentials.")
        print("\n🔧 To fix this:")
        print("   1. Set your MiniMax environment variables")
        print("   2. Ensure your API key has TTS permissions")
        print("   3. Check your account balance/quota")

if __name__ == "__main__":
    main()