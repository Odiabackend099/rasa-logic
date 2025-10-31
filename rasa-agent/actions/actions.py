from typing import Any, Text, Dict, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
import requests
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ActionLogToBackend(Action):
    """
    Custom action to log lead information to the backend API.
    Captures name, business, and phone from slots and sends to backend.
    """
    
    def name(self) -> Text:
        return "action_log_to_backend"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        # Extract slot values
        name = tracker.get_slot("name")
        business = tracker.get_slot("business")
        phone = tracker.get_slot("phone")
        
        # Validate required data
        if not all([name, business, phone]):
            logger.warning("Missing required lead data - name: %s, business: %s, phone: %s", 
                         bool(name), bool(business), bool(phone))
            return []
        
        # Prepare lead data
        lead_data = {
            "name": str(name).strip(),
            "business": str(business).strip(),
            "phone": str(phone).strip(),
            "source": "rasa_voice_agent",
            "timestamp": tracker.current_state().get("latest_event_time")
        }
        
        try:
            backend_url = os.getenv("BACKEND_URL")
            if not backend_url:
                logger.error("BACKEND_URL environment variable not set")
                return []
            
            # Ensure URL format is correct
            if not backend_url.startswith(('http://', 'https://')):
                backend_url = f"https://{backend_url}"
            
            # Make API request with timeout and proper headers
            response = requests.post(
                f"{backend_url}/api/leads",
                json=lead_data,
                timeout=10,
                headers={
                    "Content-Type": "application/json",
                    "User-Agent": "CallWaitingAI-Rasa-Agent/1.0"
                }
            )
            
            response.raise_for_status()
            logger.info("Successfully logged lead for %s (%s)", name, business)
            
        except requests.exceptions.Timeout:
            logger.error("Timeout while logging lead to backend")
        except requests.exceptions.ConnectionError:
            logger.error("Connection error while logging lead to backend")
        except requests.exceptions.HTTPError as e:
            logger.error("HTTP error while logging lead: %s", e.response.status_code)
        except Exception as e:
            logger.error("Unexpected error logging lead: %s", str(e))
        
        return []


class ActionSendToMiniMax(Action):
    """
    Custom action to send text to MiniMax TTS API for voice synthesis.
    Handles API authentication and response processing.
    """
    
    def name(self) -> Text:
        return "action_send_to_minimax"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        
        # Get the latest message text
        latest_message = tracker.latest_message
        if not latest_message:
            logger.warning("No latest message found for MiniMax TTS")
            return []
        
        original_text = latest_message.get('text', '').strip()
        if not original_text:
            logger.warning("Empty text for MiniMax TTS synthesis")
            return []
        
        # Check if this is a love-related question and provide a beautiful response
        if any(word in original_text.lower() for word in ['love', 'meaning of love', 'true love']):
            text_to_synthesize = """The true meaning of love whispers to us in the quiet moments between heartbeats. 

Love is not just an emotion, but a choice we make each day. It's the gentle touch that says "you matter" without words. It's seeing someone's flaws and choosing to stay, not despite them, but because they make that person beautifully human.

True love is patient. It doesn't rush or demand, but waits with open arms. It's the safety of knowing someone will catch you when you fall, and the courage to let yourself be vulnerable.

Love is found in small gestures - a warm cup of coffee on a cold morning, a listening ear after a difficult day, or simply sitting together in comfortable silence. It's choosing kindness when anger would be easier.

The deepest love starts with loving yourself - accepting your own imperfections and treating yourself with the same compassion you'd show a dear friend. Only then can you truly give love to others.

Love is not possession, but freedom. It's wanting the best for someone, even if that means letting them go. It's celebrating their dreams and supporting their journey, wherever it may lead.

In the end, love is the thread that connects all hearts, the light that guides us home, and the gentle reminder that we are never truly alone in this beautiful, complex world."""
        else:
            # For other messages, use the original text
            text_to_synthesize = original_text
        
        # Get MiniMax configuration from environment
        minimax_url = os.getenv("MINIMAX_API_URL")
        api_key = os.getenv("MINIMAX_API_KEY")
        group_id = os.getenv("MINIMAX_GROUP_ID")
        model = os.getenv("MINIMAX_MODEL", "speech-02-hd")
        
        # Validate required configuration
        if not all([minimax_url, api_key, group_id]):
            logger.error("Missing MiniMax configuration - URL: %s, API Key: %s, Group ID: %s",
                        bool(minimax_url), bool(api_key), bool(group_id))
            return []
        
        # Prepare request headers and body
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "User-Agent": "CallWaitingAI-Rasa-Agent/1.0"
        }
        
        # Use soft female voice for love-related content
        voice_settings = {
            "voice_id": "female-soft",
            "speed": 0.9,  # Slightly slower for gentle delivery
            "vol": 0.8,    # Moderate volume
            "pitch": 0     # Natural pitch
        } if 'love' in original_text.lower() else {
            "voice_id": "female_calm",
            "speed": 1.0,
            "vol": 1.0,
            "pitch": 0
        }
        
        request_body = {
            "group_id": group_id,
            "model": model,
            "text": text_to_synthesize,
            "voice_setting": voice_settings
        }
        
        try:
            # Make API request to MiniMax
            response = requests.post(
                minimax_url,
                headers=headers,
                json=request_body,
                timeout=15
            )
            
            response.raise_for_status()
            response_data = response.json()
            
            # Extract audio URL from response
            audio_url = response_data.get("audio_url")
            if audio_url:
                logger.info("Successfully generated TTS audio for text: %s", text_to_synthesize[:50])
                
                # Send audio URL back to dispatcher (for voice channel integration)
                dispatcher.utter_message(
                    text="Audio generated successfully",
                    custom={
                        "audio_url": audio_url,
                        "tts_provider": "minimax"
                    }
                )
            else:
                logger.warning("No audio URL in MiniMax response")
                
        except requests.exceptions.Timeout:
            logger.error("Timeout while calling MiniMax TTS API")
        except requests.exceptions.ConnectionError:
            logger.error("Connection error while calling MiniMax TTS API")
        except requests.exceptions.HTTPError as e:
            logger.error("HTTP error from MiniMax TTS API: %s", e.response.status_code)
        except ValueError as e:
            logger.error("Invalid JSON response from MiniMax TTS API: %s", str(e))
        except Exception as e:
            logger.error("Unexpected error calling MiniMax TTS API: %s", str(e))
        
        return []

