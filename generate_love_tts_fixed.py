#!/usr/bin/env python3
"""
Fixed version: Generate the 60-second love TTS using MiniMax t2a_v2 API
with correct parameter format for African male voice
"""

import requests
import json
import os
import webbrowser
from datetime import datetime

# MiniMax Configuration
MINIMAX_API_URL = "https://api.minimax.io/v1/t2a_v2"
MINIMAX_API_KEY = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJHcm91cE5hbWUiOiJPRElBIGJhY2tlbmQiLCJVc2VyTmFtZSI6Ik9ESUEgYmFja2VuZCIsIkFjY291bnQiOiIiLCJTdWJqZWN0SUQiOiIxOTMzNTEwOTg4MDAzMjgzNzUxIiwiUGhvbmUiOiIiLCJHcm91cElEIjoiMTkzMzUxMDk4Nzk5NDg5NTE0MyIsIlBhZ2VOYW1lIjoiIiwiTWFpbCI6Im9kaWFiYWNrZW5kQGdtYWlsLmNvbSIsIkNyZWF0ZVRpbWUiOiIyMDI1LTEwLTMxIDA3OjU5OjU2IiwiVG9rZW5UeXBlIjoxLCJpc3MiOiJtaW5pbWF4In0.sbtLDocbhzFgUz9ZPpjscpM5iQA0_ZuJEqQXQ3fw3gd0Rfd6iC1XIDXaeCh1PbO3S2v-UsxPu5eJGAlDEHYcLzTQgd-ZXCvpW2C5HKVN2Yw1fwdYlzhXcgaCGdFn9ZeAySI9bj-Vs0SN7DubmmU4PVeNs3RYfVuu1AyH2U_A4PDeJEFDEDpFje2RC4fertBMS6Jj9lvXBF5etDCDfzgqtQVSdXKi97Vqx7soPF4pbBxB67rh9O3TSXkkC8QXYr6hjOhnyw-zy06ixg2Xu5CLIuqBTObQEQv5VpfzCkvqZhjpfrxvH3Epif07OMbCWJP8lQ36un0RuAdyZXLBfmO8Fg"
MINIMAX_GROUP_ID = "1933510987994895143"

def create_love_response():
    """Create the beautiful 60-second love response."""
    return """The true meaning of love whispers to us in the quiet moments between heartbeats. 

Love is not just an emotion, but a choice we make each day. It's the gentle touch that says "you matter" without words. It's seeing someone's flaws and choosing to stay, not despite them, but because they make that person beautifully human.

True love is patient. It doesn't rush or demand, but waits with open arms. It's the safety of knowing someone will catch you when you fall, and the courage to let yourself be vulnerable.

Love is found in small gestures - a warm cup of coffee on a cold morning, a listening ear after a difficult day, or simply sitting together in comfortable silence. It's choosing kindness when anger would be easier.

The deepest love starts with loving yourself - accepting your own imperfections and treating yourself with the same compassion you'd show a dear friend. Only then can you truly give love to others.

Love is not possession, but freedom. It's wanting the best for someone, even if that means letting them go. It's celebrating their dreams and supporting their journey, wherever it may lead.

In the end, love is the thread that connects all hearts, the light that guides us home, and the gentle reminder that we are never truly alone in this beautiful, complex world."""

def generate_tts_audio():
    """Generate TTS audio using MiniMax t2a_v2 API with correct format."""
    
    love_text = create_love_response()
    
    print("💕 Generating Love TTS with African Male Voice (Fixed)")
    print("=" * 60)
    print(f"📝 Text length: {len(love_text)} characters")
    print(f"🎤 Voice: African Male (moss_audio)")
    print(f"🌍 API: {MINIMAX_API_URL}")
    print("=" * 60)
    
    # Prepare headers
    headers = {
        'Authorization': f'Bearer {MINIMAX_API_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Corrected payload format for t2a_v2
    payload = {
        "group_id": MINIMAX_GROUP_ID,
        "text": love_text,
        "voice_setting": {
            "voice_id": "moss_audio_4e6eb029-ab89-11f0-a74c-2a7a0b4baedc",
            "speed": 0.9,
            "vol": 0.8,
            "pitch": 0
        },
        "audio_setting": {
            "sample_rate": 32000,
            "bitrate": 128000,
            "format": "mp3"
        },
        "model": "speech-02-hd"
    }
    
    print("🚀 Calling MiniMax TTS API with corrected format...")
    print(f"📊 Payload structure:")
    print(f"   - Group ID: {MINIMAX_GROUP_ID}")
    print(f"   - Voice ID: moss_audio_4e6eb029-ab89-11f0-a74c-2a7a0b4baedc")
    print(f"   - Speed: {payload['voice_setting']['speed']}")
    print(f"   - Volume: {payload['voice_setting']['vol']}")
    print(f"   - Model: {payload['model']}")
    
    try:
        response = requests.post(
            MINIMAX_API_URL,
            headers=headers,
            json=payload,
            timeout=90  # Longer timeout for TTS generation
        )
        
        print(f"📡 Response status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ TTS generation successful!")
            
            # Save the full response
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            result_file = f"love_tts_fixed_{timestamp}.json"
            
            with open(result_file, 'w') as f:
                json.dump({
                    'text': love_text,
                    'response': result,
                    'generated_at': timestamp,
                    'payload_used': payload
                }, f, indent=2)
            
            print(f"💾 Full response saved to: {result_file}")
            
            # Look for audio URL in various possible locations
            audio_url = None
            
            if 'audio_url' in result:
                audio_url = result['audio_url']
            elif 'data' in result:
                if isinstance(result['data'], dict) and 'audio_url' in result['data']:
                    audio_url = result['data']['audio_url']
                elif isinstance(result['data'], str):
                    audio_url = result['data']  # Sometimes the URL is directly in data
            elif 'url' in result:
                audio_url = result['url']
            elif 'audio' in result:
                if isinstance(result['audio'], dict) and 'url' in result['audio']:
                    audio_url = result['audio']['url']
                elif isinstance(result['audio'], str):
                    audio_url = result['audio']
            
            if audio_url:
                print(f"🎧 Audio URL found: {audio_url}")
                
                # Try to auto-play
                try:
                    print("🎵 Attempting to open audio in browser...")
                    webbrowser.open(audio_url)
                    print("✅ Audio should be playing in your browser!")
                except Exception as e:
                    print(f"⚠️  Could not auto-open browser: {e}")
                    print(f"🔗 Please manually open: {audio_url}")
                
                return audio_url
                
            else:
                print("❌ No audio URL found in response")
                print("📋 Full response structure:")
                print(json.dumps(result, indent=2))
                return None
                
        else:
            print(f"❌ API Error: HTTP {response.status_code}")
            try:
                error_response = response.json()
                print("📋 Error details:")
                print(json.dumps(error_response, indent=2))
            except:
                print(f"📋 Raw response: {response.text}")
            return None
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out (TTS generation can take time)")
        return None
    except requests.exceptions.ConnectionError:
        print("❌ Connection error - check your internet connection")
        return None
    except requests.exceptions.HTTPError as e:
        print(f"❌ HTTP error: {e}")
        return None
    except Exception as e:
        print(f"❌ Unexpected error: {str(e)}")
        return None

def try_alternative_endpoint():
    """Try the original t2a endpoint as fallback."""
    
    love_text = create_love_response()
    
    print("\n🔄 Trying alternative endpoint: /v1/t2a")
    
    # Alternative endpoint
    alt_url = "https://api.minimax.io/v1/t2a"
    
    headers = {
        'Authorization': f'Bearer {MINIMAX_API_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Simpler payload for t2a endpoint
    payload = {
        "group_id": MINIMAX_GROUP_ID,
        "model": "speech-02-hd",
        "text": love_text,
        "voice_setting": {
            "voice_id": "moss_audio_4e6eb029-ab89-11f0-a74c-2a7a0b4baedc",
            "speed": 0.9,
            "vol": 0.8,
            "pitch": 0
        }
    }
    
    try:
        response = requests.post(alt_url, headers=headers, json=payload, timeout=90)
        print(f"📡 Alternative endpoint response: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            # Save response
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            result_file = f"love_tts_alt_{timestamp}.json"
            
            with open(result_file, 'w') as f:
                json.dump({
                    'text': love_text,
                    'response': result,
                    'endpoint': alt_url,
                    'generated_at': timestamp
                }, f, indent=2)
            
            print(f"💾 Alternative response saved to: {result_file}")
            
            # Look for audio URL
            if 'audio_url' in result:
                audio_url = result['audio_url']
                print(f"🎧 Audio URL from alternative endpoint: {audio_url}")
                
                try:
                    webbrowser.open(audio_url)
                    print("✅ Audio should be playing!")
                except:
                    print(f"🔗 Manual link: {audio_url}")
                
                return audio_url
            else:
                print("📋 Alternative endpoint response:")
                print(json.dumps(result, indent=2))
        else:
            print(f"❌ Alternative endpoint also failed: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Alternative endpoint error: {e}")
    
    return None

def main():
    """Main function."""
    
    print("🎯 Love TTS Generator - Fixed Version")
    print("Using your MiniMax credentials with corrected API format")
    print()
    
    # Try the main endpoint first
    audio_url = generate_tts_audio()
    
    # If that fails, try alternative endpoint
    if not audio_url:
        audio_url = try_alternative_endpoint()
    
    if audio_url:
        print("\n🎉 SUCCESS! Your love TTS is ready!")
        print(f"🎧 Audio URL: {audio_url}")
        print("\n💡 What happened:")
        print("   ✅ Connected to MiniMax API")
        print("   ✅ Used African male voice (moss_audio)")
        print("   ✅ Generated ~60 second love meditation")
        print("   ✅ Applied gentle voice settings")
        print("   ✅ Audio should be playing automatically")
        
    else:
        print("\n❌ Both endpoints failed")
        print("🔧 This might be due to:")
        print("   - API endpoint changes")
        print("   - Parameter format requirements")
        print("   - Voice ID format issues")
        print("   - Account permissions")
        print("\n📋 Check the saved JSON files for detailed error information")

if __name__ == "__main__":
    main()