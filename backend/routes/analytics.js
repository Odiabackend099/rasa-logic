/**
 * Analytics and Dashboard API endpoints
 * Provides data for dashboard widgets and reports
 */

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const logger = require('../utils/logger');
const router = express.Router();

const SUPABASE_URL = process.env.SUPABASE_URL || '';
const SUPABASE_KEY = process.env.SUPABASE_KEY || '';

const supabase = SUPABASE_URL && SUPABASE_KEY
  ? createClient(SUPABASE_URL, SUPABASE_KEY)
  : null;

/**
 * GET /api/analytics/conversations
 * Get conversation statistics
 */
router.get('/conversations', async (req, res) => {
  try {
    const { start_date, end_date, channel, limit = 100 } = req.query;

    let query = supabase
      .from('conversations')
      .select('*')
      .order('started_at', { ascending: false })
      .limit(parseInt(limit));

    if (start_date) {
      query = query.gte('started_at', start_date);
    }
    if (end_date) {
      query = query.lte('started_at', end_date);
    }
    if (channel) {
      query = query.eq('channel', channel);
    }

    const { data, error } = await query;

    if (error) throw error;

    res.json({
      conversations: data,
      count: data.length
    });

  } catch (error) {
    logger.error('Analytics error', { endpoint: '/conversations', error: error.message });
    res.status(500).json({ error: 'Failed to fetch conversations' });
  }
});

/**
 * GET /api/analytics/intents
 * Get intent statistics and failed intents
 */
router.get('/intents', async (req, res) => {
  try {
    const { start_date, end_date, min_confidence = 0.5 } = req.query;

    let query = supabase
      .from('call_logs')
      .select('detected_intent, confidence, channel, language, timestamp')
      .not('detected_intent', 'is', null);

    if (start_date) {
      query = query.gte('timestamp', start_date);
    }
    if (end_date) {
      query = query.lte('timestamp', end_date);
    }

    const { data, error } = await query;

    if (error) throw error;

    // Aggregate intent statistics
    const intentStats = {};
    const failedIntents = [];

    data.forEach(log => {
      const intent = log.detected_intent;
      if (!intentStats[intent]) {
        intentStats[intent] = {
          intent: intent,
          count: 0,
          total_confidence: 0,
          avg_confidence: 0,
          channels: {},
          languages: {}
        };
      }

      intentStats[intent].count++;
      intentStats[intent].total_confidence += log.confidence || 0;
      
      // Track by channel
      if (log.channel) {
        intentStats[intent].channels[log.channel] = 
          (intentStats[intent].channels[log.channel] || 0) + 1;
      }

      // Track by language
      if (log.language) {
        intentStats[intent].languages[log.language] = 
          (intentStats[intent].languages[log.language] || 0) + 1;
      }

      // Check for failed intents (low confidence or out_of_scope)
      if ((log.confidence && log.confidence < parseFloat(min_confidence)) ||
          intent === 'out_of_scope') {
        failedIntents.push({
          intent: intent,
          confidence: log.confidence,
          timestamp: log.timestamp,
          channel: log.channel
        });
      }
    });

    // Calculate average confidence
    Object.keys(intentStats).forEach(intent => {
      const stats = intentStats[intent];
      stats.avg_confidence = stats.total_confidence / stats.count;
      delete stats.total_confidence;
    });

    res.json({
      intent_statistics: Object.values(intentStats),
      failed_intents: failedIntents,
      total_interactions: data.length
    });

  } catch (error) {
    logger.error('Analytics error', { endpoint: '/conversations', error: error.message });
    res.status(500).json({ error: 'Failed to fetch intent statistics' });
  }
});

/**
 * GET /api/analytics/leads
 * Get lead statistics
 */
router.get('/leads', async (req, res) => {
  try {
    const { start_date, end_date, status } = req.query;

    let query = supabase
      .from('leads')
      .select('*')
      .order('created_at', { ascending: false });

    if (start_date) {
      query = query.gte('created_at', start_date);
    }
    if (end_date) {
      query = query.lte('created_at', end_date);
    }
    if (status) {
      query = query.eq('status', status);
    }

    const { data, error } = await query;

    if (error) throw error;

    // Calculate statistics
    const stats = {
      total: data.length,
      by_status: {},
      by_channel: {},
      by_service: {}
    };

    data.forEach(lead => {
      // Count by status
      stats.by_status[lead.status] = (stats.by_status[lead.status] || 0) + 1;
      
      // Count by channel
      if (lead.source_channel) {
        stats.by_channel[lead.source_channel] = 
          (stats.by_channel[lead.source_channel] || 0) + 1;
      }

      // Count by service interest
      if (lead.service_interest) {
        stats.by_service[lead.service_interest] = 
          (stats.by_service[lead.service_interest] || 0) + 1;
      }
    });

    res.json({
      leads: data,
      statistics: stats
    });

  } catch (error) {
    logger.error('Analytics error', { endpoint: '/conversations', error: error.message });
    res.status(500).json({ error: 'Failed to fetch leads' });
  }
});

/**
 * GET /api/analytics/dashboard
 * Get dashboard summary statistics
 */
router.get('/dashboard', async (req, res) => {
  try {
    const { start_date, end_date } = req.query;

    // Get date range (default to last 7 days)
    const end = end_date ? new Date(end_date) : new Date();
    const start = start_date ? new Date(start_date) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    // Fetch all required data
    const [conversationsRes, callLogsRes, leadsRes] = await Promise.all([
      supabase
        .from('conversations')
        .select('*')
        .gte('started_at', start.toISOString())
        .lte('started_at', end.toISOString()),
      supabase
        .from('call_logs')
        .select('*')
        .gte('timestamp', start.toISOString())
        .lte('timestamp', end.toISOString()),
      supabase
        .from('leads')
        .select('*')
        .gte('created_at', start.toISOString())
        .lte('created_at', end.toISOString())
    ]);

    const conversations = conversationsRes.data || [];
    const callLogs = callLogsRes.data || [];
    const leads = leadsRes.data || [];

    // Calculate statistics
    const dashboard = {
      date_range: {
        start: start.toISOString(),
        end: end.toISOString()
      },
      summary: {
        total_conversations: conversations.length,
        total_interactions: callLogs.length,
        total_leads: leads.length,
        active_conversations: conversations.filter(c => c.status === 'active').length,
        handed_off: conversations.filter(c => c.status === 'handed_off').length
      },
      by_channel: {},
      by_language: {},
      top_intents: {},
      conversion_rate: leads.length > 0 
        ? (leads.filter(l => l.status === 'converted').length / leads.length * 100).toFixed(2)
        : 0
    };

    // Aggregate by channel
    conversations.forEach(c => {
      dashboard.by_channel[c.channel] = (dashboard.by_channel[c.channel] || 0) + 1;
    });

    // Aggregate by language
    callLogs.forEach(log => {
      const lang = log.language || 'en';
      dashboard.by_language[lang] = (dashboard.by_language[lang] || 0) + 1;
    });

    // Top intents
    callLogs.forEach(log => {
      if (log.detected_intent) {
        dashboard.top_intents[log.detected_intent] = 
          (dashboard.top_intents[log.detected_intent] || 0) + 1;
      }
    });

    // Sort top intents
    dashboard.top_intents = Object.entries(dashboard.top_intents)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .reduce((obj, [intent, count]) => {
        obj[intent] = count;
        return obj;
      }, {});

    res.json(dashboard);

  } catch (error) {
    logger.error('Analytics error', { endpoint: '/conversations', error: error.message });
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

/**
 * GET /api/analytics/session/:sessionId
 * Get full conversation details for a session
 */
router.get('/session/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;

    // Fetch conversation and logs
    const [conversationRes, logsRes] = await Promise.all([
      supabase
        .from('conversations')
        .select('*')
        .eq('session_id', sessionId)
        .single(),
      supabase
        .from('call_logs')
        .select('*')
        .eq('session_id', sessionId)
        .order('timestamp', { ascending: true })
    ]);

    const conversation = conversationRes.data;
    const logs = logsRes.data || [];

    if (!conversation && logs.length === 0) {
      return res.status(404).json({ error: 'Session not found' });
    }

    res.json({
      conversation: conversation,
      logs: logs,
      message_count: logs.length
    });

  } catch (error) {
    logger.error('Analytics error', { endpoint: '/conversations', error: error.message });
    res.status(500).json({ error: 'Failed to fetch session data' });
  }
});

module.exports = router;

