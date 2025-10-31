#!/usr/bin/env python3
"""
Extract the love TTS audio from hex-encoded MiniMax response and save as MP3
"""

import json
import os
from datetime import datetime

def extract_audio_from_response():
    """Extract hex-encoded audio data from the TTS response file."""
    
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
        
        # Get the response data
        response = data['response']
        audio_data = response['data']['audio']
        audio_info = response['extra_info']
        
        print(f"📊 Audio info:")
        print(f"   - Length: {audio_info['audio_length']} ms ({audio_info['audio_length']/1000:.1f} seconds)")
        print(f"   - Size: {audio_info['audio_size']:,} bytes ({audio_info['audio_size']/1024/1024:.1f} MB)")
        print(f"   - Format: {audio_info['audio_format']}")
        print(f"   - Sample Rate: {audio_info['audio_sample_rate']:,} Hz")
        print(f"   - Bitrate: {audio_info['bitrate']:,} bps")
        print(f"   - Channels: {audio_info['audio_channel']}")
        
        # Convert hex string to bytes
        try:
            print("🔄 Converting hex data to audio bytes...")
            audio_bytes = bytes.fromhex(audio_data)
            print(f"✅ Successfully converted {len(audio_bytes):,} bytes of audio data")
            
            # Verify it's an MP3 file (should start with ID3 or FF FB)
            if audio_bytes[:3] == b'ID3':
                print("✅ Confirmed: Valid MP3 file with ID3 header")
            elif audio_bytes[:2] == b'\xff\xfb':
                print("✅ Confirmed: Valid MP3 file with MPEG header")
            else:
                print(f"⚠️  Unusual header: {audio_bytes[:10].hex()}")
            
            # Save as MP3 file
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            output_file = f"love_meditation_african_male_{timestamp}.mp3"
            
            with open(output_file, 'wb') as f:
                f.write(audio_bytes)
            
            print(f"💾 Audio saved as: {output_file}")
            
            # Verify file size matches
            actual_size = os.path.getsize(output_file)
            expected_size = audio_info['audio_size']
            
            if actual_size == expected_size:
                print(f"✅ File size verification passed: {actual_size:,} bytes")
            else:
                print(f"⚠️  Size mismatch: got {actual_size:,}, expected {expected_size:,}")
            
            # Try to play it
            try:
                import subprocess
                import platform
                
                system = platform.system()
                print(f"🎵 Attempting to play on {system}...")
                
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
            
        except ValueError as e:
            print(f"❌ Failed to convert hex data: {e}")
            print("🔍 Audio data preview (first 200 chars):")
            print(audio_data[:200])
            return None
            
    except Exception as e:
        print(f"❌ Error processing response file: {e}")
        return None

def main():
    """Main function."""
    
    print("🎯 Love TTS Audio Extractor (Hex Version)")
    print("Extracting your 88-second love meditation from MiniMax response")
    print("=" * 65)
    
    audio_file = extract_audio_from_response()
    
    if audio_file:
        print("\n🎉 SUCCESS! Your love meditation is ready!")
        print(f"🎧 Audio file: {audio_file}")
        print(f"⏱️  Duration: ~88 seconds of beautiful love meditation")
        print(f"🎤 Voice: African Male (moss_audio)")
        print(f"💕 Content: The true meaning of love")
        print(f"🎵 Quality: 128 kbps MP3, 32kHz, Mono")
        
        print("\n💡 You can now:")
        print(f"   - Play the file: {audio_file}")
        print("   - Share it with others")
        print("   - Use it in your applications")
        print("   - Upload it to your platforms")
        print("   - Integrate with your Rasa system")
        
        print("\n🎭 The Experience:")
        print("   A gentle, deep meditation on love's true meaning")
        print("   Spoken with warmth and wisdom")
        print("   Perfect for reflection and inspiration")
        print("   Exactly what you requested - soft and meaningful")
        
    else:
        print("\n❌ Could not extract audio")
        print("🔧 Please check the JSON response file for details")

if __name__ == "__main__":
    main()