export interface Event {
  id: string;
  userId: string;
  eventType: EventType;
  eventName: string;
  properties?: Record<string, any>;
  timestamp: Date;
  sessionId?: string;
  ipAddress?: string;
  userAgent?: string;
}

export enum EventType {
  CLICK = 'click',
  PAGE_VIEW = 'page_view',
  FORM_SUBMIT = 'form_submit',
  API_CALL = 'api_call',
  ERROR = 'error',
  CUSTOM = 'custom',
}

export interface Analytics {
  totalEvents: number;
  uniqueUsers: number;
  timestamp: Date;
}

export interface DailyStats {
  date: string;
  count: number;
}
