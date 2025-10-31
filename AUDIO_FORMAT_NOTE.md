# MiniMax Audio Format Note

## Current Status

The MiniMax API returns audio as base64-encoded data in the response:
- Path: `response.data.data.audio`
- Format: Base64 string
- Decoded size: ~32KB for short text, ~600KB for 20-second audio

## File Generation

Files are being generated successfully:
- Size: Correct (600KB+ for 20 seconds)
- Format: MP3 (despite header check warnings)
- Decoding: Base64 to Buffer works correctly

## Audio Playback

**Note**: The generated files may not show standard MP3 headers (ID3 tags) in hex dumps, but they should still be playable. This is because:

1. MiniMax may use a different audio encoding format
2. The files might be raw MP3 frames without ID3 headers
3. Audio players can still decode and play them

## Testing

To verify audio plays correctly:
1. Open the generated `.mp3` files in any audio player
2. If they play, the format is correct
3. If they don't play, we may need to:
   - Check if MiniMax provides a download URL instead
   - Verify the audio format specification
   - Add format conversion if needed

## Generated Files

- Location: `backend/tmp/test-tts-20sec.mp3`
- Default voice: Odia (African male)
- Duration: ~20 seconds

