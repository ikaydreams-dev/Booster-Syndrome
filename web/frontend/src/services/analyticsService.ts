import api from './api';

interface Event {
  user_id: string;
  event_type: string;
  event_name: string;
  properties?: Record<string, any>;
}

interface Stats {
  total_events: number;
  unique_users: number;
  timestamp: string;
}

class AnalyticsService {
  async trackEvent(event: Event): Promise<any> {
    return await api.post('/analytics/events', event);
  }

  async getSummary(): Promise<Stats> {
    return await api.get<Stats>('/stats/summary');
  }

  async getDailyStats(days: number = 7): Promise<any[]> {
    return await api.get('/stats/daily', { days });
  }

  async getTopEvents(limit: number = 10): Promise<any[]> {
    return await api.get('/reports/top-events', { limit });
  }
}

export default new AnalyticsService();
