#!/usr/bin/env python3
"""
Extract the love TTS audio from the MiniMax response and save as MP3
"""

import json
import base64
import os
from datetime import datetime

def extract_audio_from_response():
    """Extract audio data from the TTS response file."""
    
    # Find the latest TTS response file
    response_file = "love_tts_fixed_20251031_072301.json"
    
    if not os.path.exists(response_file):
        print(f"❌ Response file not found: {response_file}")
        return None
    
    print(f"📂 Reading response from: {response_file}")
    
    try:
        with open(response_file, 'r') as f:
            data = json.load(f)
        
        print("✅ Response file loaded successfully")
        
        # Check response structure
        if 'response' not in data:
            print("❌ No 'response' key in data")
            return None
        
        response = data['response']
        
        # Look for audio data in various possible locations
        audio_data = None
        audio_info = {}
        
        if 'data' in response:
            response_data = response['data']
            
            # Check for base64 audio data
            if isinstance(response_data, dict):
                # Look for audio in various keys
                for key in ['audio', 'audio_data', 'content', 'file', 'mp3']:
                    if key in response_data:
                        audio_data = response_data[key]
                        print(f"🎵 Found audio data in key: {key}")
                        break
                
                # Get audio info
                if 'extra_info' in response:
                    audio_info = response['extra_info']
                    print(f"📊 Audio info:")
                    print(f"   - Length: {audio_info.get('audio_length', 'unknown')} ms")
                    print(f"   - Size: {audio_info.get('audio_size', 'unknown')} bytes")
                    print(f"   - Format: {audio_info.get('audio_format', 'unknown')}")
                    print(f"   - Sample Rate: {audio_info.get('audio_sample_rate', 'unknown')} Hz")
                    print(f"   - Bitrate: {audio_info.get('bitrate', 'unknown')} bps")
            
            elif isinstance(response_data, str):
                # The data might be directly the base64 string
                audio_data = response_data
                print("🎵 Found audio data as direct string")
        
        if not audio_data:
            print("❌ No audio data found in response")
            print("📋 Available keys in response:")
            print(json.dumps(list(response.keys()), indent=2))
            if 'data' in response:
                print("📋 Available keys in response.data:")
                if isinstance(response['data'], dict):
                    print(json.dumps(list(response['data'].keys()), indent=2))
            return None
        
        # Try to decode the base64 audio data
        try:
            print("🔄 Decoding base64 audio data...")
            audio_bytes = base64.b64decode(audio_data)
            print(f"✅ Successfully decoded {len(audio_bytes)} bytes of audio data")
            
            # Save as MP3 file
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_file = f"love_meditation_african_male_{timestamp}.mp3"
            
            with open(output_file, 'wb') as f:
                f.write(audio_bytes)
            
            print(f"💾 Audio saved as: {output_file}")
            
            # Try to play it
            try:
                import subprocess
                import platform
                
                system = platform.system()
                if system == "Darwin":  # macOS
                    subprocess.run(["open", output_file])
                    print("🎵 Audio should be playing on macOS!")
                elif system == "Linux":
                    subprocess.run(["xdg-open", output_file])
                    print("🎵 Audio should be playing on Linux!")
                elif system == "Windows":
                    os.startfile(output_file)
                    print("🎵 Audio should be playing on Windows!")
                else:
                    print(f"🔗 Please manually play: {output_file}")
                    
            except Exception as e:
                print(f"⚠️  Could not auto-play: {e}")
                print(f"🔗 Please manually play: {output_file}")
            
            return output_file
            
        except Exception as e:
            print(f"❌ Failed to decode base64 audio: {e}")
            print("🔍 Audio data preview (first 100 chars):")
            print(audio_data[:100] if len(audio_data) > 100 else audio_data)
            return None
            
    except Exception as e:
        print(f"❌ Error reading response file: {e}")
        return None

def main():
    """Main function."""
    
    print("🎯 Love TTS Audio Extractor")
    print("Extracting your 60-second love meditation from MiniMax response")
    print("=" * 60)
    
    audio_file = extract_audio_from_response()
    
    if audio_file:
        print("\n🎉 SUCCESS! Your love meditation is ready!")
        print(f"🎧 Audio file: {audio_file}")
        print(f"⏱️  Duration: ~88 seconds of beautiful love meditation")
        print(f"🎤 Voice: African Male (moss_audio)")
        print(f"💕 Content: The true meaning of love")
        
        print("\n💡 You can now:")
        print(f"   - Play the file: {audio_file}")
        print("   - Share it with others")
        print("   - Use it in your applications")
        print("   - Upload it to your platforms")
        
        # Show file info
        try:
            file_size = os.path.getsize(audio_file)
            print(f"\n📊 File details:")
            print(f"   - Size: {file_size:,} bytes ({file_size/1024/1024:.1f} MB)")
            print(f"   - Format: MP3")
            print(f"   - Quality: 128 kbps, 32kHz")
        except:
            pass
            
    else:
        print("\n❌ Could not extract audio")
        print("🔧 The TTS generation might have failed or returned a different format")
        print("📋 Check the JSON response file for details")

if __name__ == "__main__":
    main()