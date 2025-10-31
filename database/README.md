# Database Setup

This directory contains the Supabase database schema and setup instructions.

## Setup Instructions

1. **Create Supabase Project**
   - Go to https://supabase.com
   - Create a new project
   - Note your project URL and anon key

2. **Run Schema**
   - Open your Supabase SQL Editor
   - Copy and paste the contents of `schema.sql`
   - Execute the SQL script

3. **Configure Environment Variables**
   - Update `.env` files in both `rasa-agent/` and `backend/` directories:
     ```
     SUPABASE_URL=your_project_url
     SUPABASE_KEY=your_anon_key
     ```

## Tables

### call_logs
Stores each conversation turn/interaction with user input, detected intent, confidence, and bot response.

### leads
Stores captured leads with contact information, service interests, and booking details.

### conversations
Stores full conversation sessions with metadata and status.

### handoffs
Tracks human agent handoff requests and status.

## Row Level Security (RLS)

The schema includes RLS policies. In production, configure proper policies based on your authentication setup.

## Indexes

All tables have appropriate indexes for common query patterns:
- Session ID lookups
- Timestamp ranges
- Status filtering
- Channel filtering

