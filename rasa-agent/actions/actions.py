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
        
        text_to_synthesize = latest_message.get('text', '').strip()
        if not text_to_synthesize:
            logger.warning("Empty text for MiniMax TTS synthesis")
            return []
        
        # Get MiniMax configuration from environment
        minimax_url = os.getenv("MINIMAX_API_URL")
        api_key = os.getenv("MINIMAX_API_KEY")
        group_id = os.getenv("MINIMAX_GROUP_ID")
        model = os.getenv("MINIMAX_MODEL", "speech-01")
        
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
        
        request_body = {
            "group_id": group_id,
            "model": model,
            "text": text_to_synthesize,
            "voice_setting": {
                "voice_id": "female_calm",
                "speed": 1.0,
                "vol": 1.0,
                "pitch": 0
            }
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

