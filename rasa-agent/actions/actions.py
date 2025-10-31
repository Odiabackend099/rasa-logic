"""
Custom actions for CallWaitingAI Rasa agent.
Handles lead capture, booking, logging, and Supabase integration.
"""

import os
import logging
from typing import Any, Text, Dict, List
from datetime import datetime
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet
from supabase import create_client, Client

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Supabase client
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

supabase: Client = None
if SUPABASE_URL and SUPABASE_KEY:
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    logger.info("Supabase client initialized")
else:
    logger.warning("Supabase credentials not found. Database actions will be disabled.")


class ActionCaptureLead(Action):
    """Capture lead information and store in Supabase leads table."""

    def name(self) -> Text:
        return "action_capture_lead"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        """Extract lead information and store in database."""
        
        # Extract information from tracker
        name = tracker.get_slot("name") or ""
        phone_number = tracker.get_slot("phone_number") or ""
        email = tracker.get_slot("email") or ""
        service_interest = tracker.get_slot("service_type") or ""
        booking_date = tracker.get_slot("booking_date") or None
        session_id = tracker.sender_id
        channel = tracker.get_slot("channel") or "unknown"
        
        # Prepare lead data
        lead_data = {
            "session_id": session_id,
            "name": name,
            "phone_number": phone_number,
            "email": email,
            "service_interest": service_interest,
            "booking_date": booking_date,
            "status": "new",
            "source_channel": channel,
            "created_at": datetime.utcnow().isoformat(),
            "metadata": {
                "intent": tracker.latest_message.get("intent", {}).get("name", ""),
                "confidence": tracker.latest_message.get("intent", {}).get("confidence", 0),
            }
        }
        
        # Store in Supabase
        if supabase:
            try:
                result = supabase.table("leads").insert(lead_data).execute()
                logger.info(f"Lead captured: {result.data}")
                dispatcher.utter_message(
                    text="Thank you! I've saved your information. Someone from our team will contact you soon."
                )
            except Exception as e:
                logger.error(f"Error capturing lead: {e}")
                dispatcher.utter_message(
                    text="I've noted your information. We'll be in touch shortly."
                )
        else:
            logger.warning("Supabase not configured. Lead not saved.")
            dispatcher.utter_message(
                text="Thank you for your interest! We'll get back to you soon."
            )
        
        return []


class ActionStoreBooking(Action):
    """Store booking information in database."""

    def name(self) -> Text:
        return "action_store_booking"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        """Store booking details."""
        
        booking_date = tracker.get_slot("booking_date")
        booking_time = tracker.get_slot("booking_time")
        service_type = tracker.get_slot("service_type")
        session_id = tracker.sender_id
        
        if not booking_date:
            dispatcher.utter_message(
                text="I need a date to complete the booking. When would you like to book?"
            )
            return []
        
        booking_data = {
            "session_id": session_id,
            "booking_date": booking_date,
            "booking_time": booking_time or "",
            "service_type": service_type or "",
            "status": "confirmed",
            "created_at": datetime.utcnow().isoformat(),
        }
        
        if supabase:
            try:
                # Check if leads table exists, if not use a bookings table
                result = supabase.table("leads").update({
                    "booking_date": booking_date,
                    "booking_time": booking_time,
                    "status": "contacted"
                }).eq("session_id", session_id).execute()
                
                if not result.data:
                    # Create new lead entry with booking
                    lead_data = {
                        **booking_data,
                        "name": tracker.get_slot("name") or "",
                        "phone_number": tracker.get_slot("phone_number") or "",
                        "status": "contacted"
                    }
                    supabase.table("leads").insert(lead_data).execute()
                
                logger.info(f"Booking stored: {booking_data}")
            except Exception as e:
                logger.error(f"Error storing booking: {e}")
        
        return []


class ActionLogConversation(Action):
    """Log each conversation turn to Supabase call_logs table."""

    def name(self) -> Text:
        return "action_log_conversation"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        """Log conversation turn."""
        
        latest_message = tracker.latest_message
        intent_name = latest_message.get("intent", {}).get("name", "")
        confidence = latest_message.get("intent", {}).get("confidence", 0)
        user_input = latest_message.get("text", "")
        session_id = tracker.sender_id
        channel = tracker.get_slot("channel") or "unknown"
        language = tracker.get_slot("language") or "en"
        
        # Get bot response (last message sent)
        bot_response = ""
        if tracker.latest_bot_utterance:
            bot_response = tracker.latest_bot_utterance.get("text", "")
        
        log_data = {
            "session_id": session_id,
            "channel": channel,
            "user_input": user_input,
            "detected_intent": intent_name,
            "confidence": confidence,
            "bot_response": bot_response,
            "language": language,
            "timestamp": datetime.utcnow().isoformat(),
            "metadata": {
                "entities": latest_message.get("entities", []),
                "slots": dict(tracker.current_slot_values()),
            }
        }
        
        if supabase:
            try:
                supabase.table("call_logs").insert(log_data).execute()
                logger.debug(f"Conversation logged: {session_id}")
            except Exception as e:
                logger.error(f"Error logging conversation: {e}")
        
        return []


class ActionHumanHandoff(Action):
    """Handle human agent handoff."""

    def name(self) -> Text:
        return "action_human_handoff"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        """Trigger human handoff workflow."""
        
        session_id = tracker.sender_id
        channel = tracker.get_slot("channel") or "unknown"
        
        handoff_data = {
            "session_id": session_id,
            "channel": channel,
            "status": "handoff_requested",
            "requested_at": datetime.utcnow().isoformat(),
            "context": {
                "last_intent": tracker.latest_message.get("intent", {}).get("name", ""),
                "conversation_history": [
                    {
                        "user": event.get("text", ""),
                        "bot": event.get("data", {}).get("text", "")
                    }
                    for event in tracker.events
                    if event.get("event") in ["user", "bot"]
                ]
            }
        }
        
        if supabase:
            try:
                # Log handoff request
                supabase.table("call_logs").insert({
                    "session_id": session_id,
                    "channel": channel,
                    "user_input": "HUMAN_HANDOFF_REQUEST",
                    "detected_intent": "human_handoff_request",
                    "confidence": 1.0,
                    "bot_response": "Connecting to human agent...",
                    "timestamp": datetime.utcnow().isoformat(),
                    "metadata": handoff_data
                }).execute()
                
                logger.info(f"Human handoff requested: {session_id}")
                
                # TODO: Integrate with actual handoff system (webhook, queue, etc.)
                # This could trigger a webhook to your backend or notification system
                
            except Exception as e:
                logger.error(f"Error processing handoff: {e}")
        
        # Set a flag for handoff
        return [SlotSet("handoff_requested", True)]


class ActionGetServiceInfo(Action):
    """Get detailed service information."""

    def name(self) -> Text:
        return "action_get_service_info"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        """Retrieve service information."""
        
        service_type = tracker.get_slot("service_type") or ""
        
        # Service information mapping
        service_info = {
            "call management": "Our AI-powered call management system handles incoming calls intelligently, routes them appropriately, and ensures no call goes unanswered.",
            "booking system": "Our automated booking system allows customers to schedule appointments 24/7, with automatic reminders and calendar integration.",
            "customer support": "We provide 24/7 AI customer support that can handle common inquiries, escalate complex issues, and maintain consistent service quality.",
            "lead capture": "Our lead capture system automatically collects and qualifies leads from calls and conversations, ensuring you never miss a potential customer.",
        }
        
        if service_type:
            info = service_info.get(service_type.lower(), "")
            if info:
                dispatcher.utter_message(text=info)
            else:
                dispatcher.utter_message(
                    text=f"For detailed information about {service_type}, I can connect you with our team."
                )
        else:
            dispatcher.utter_message(
                text="Which specific service would you like to learn more about?"
            )
        
        return []


class ActionCheckAvailability(Action):
    """Check booking availability for requested date/time."""

    def name(self) -> Text:
        return "action_check_availability"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        """Check if requested time slot is available."""
        
        booking_date = tracker.get_slot("booking_date")
        booking_time = tracker.get_slot("booking_time")
        
        if not booking_date:
            return []
        
        # TODO: Implement actual availability check from database
        # For now, assume availability
        
        available = True  # Placeholder
        
        if not available:
            dispatcher.utter_message(
                text=f"Unfortunately, {booking_date} at {booking_time} is not available. Would you like to choose another time?"
            )
            return [SlotSet("booking_date", None), SlotSet("booking_time", None)]
        
        return []


class ActionSendConfirmation(Action):
    """Send booking confirmation."""

    def name(self) -> Text:
        return "action_send_confirmation"

    def run(
        self,
        dispatcher: CollectingDispatcher,
        tracker: Tracker,
        domain: Dict[Text, Any],
    ) -> List[Dict[Text, Any]]:
        """Send confirmation message/email."""
        
        booking_date = tracker.get_slot("booking_date")
        booking_time = tracker.get_slot("booking_time")
        
        # TODO: Implement actual confirmation sending (email, SMS, etc.)
        logger.info(f"Confirmation sent for booking: {booking_date} at {booking_time}")
        
        return []

