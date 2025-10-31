"""
Response formatter for Marcy personality
Ensures responses are warm, professional, and max 25 words
"""

def format_marcy_response(text: str, max_words: int = 25) -> str:
    """
    Format response to match Marcy's personality:
    - Warm, professional, efficient
    - Max 25 words
    - Clear English only
    """
    if not text:
        return "I'm sorry, could you repeat that?"
    
    # Count words
    words = text.split()
    
    # Truncate if too long
    if len(words) > max_words:
        # Try to find a natural break point
        truncated = words[:max_words]
        # Remove incomplete sentences
        if truncated[-1][-1] not in '.!?':
            # Remove last word if it doesn't end sentence
            truncated = truncated[:-1]
        text = ' '.join(truncated)
        # Ensure it ends with punctuation
        if text[-1] not in '.!?':
            text += '.'
    
    # Ensure professional tone
    text = text.strip()
    
    # Capitalize first letter
    if text:
        text = text[0].upper() + text[1:]
    
    return text


def get_marcy_closing() -> str:
    """Return Marcy's standard closing line."""
    return "Thank you for calling CallWaitingAI. Have a wonderful day."

