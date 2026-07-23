export interface Event {
  id: string;
  aggregateId: string;
  aggregateType: string;
  eventType: string;
  data: any;
  metadata: Record<string, any>;
  version: number;
  timestamp: Date;
}

export interface Snapshot {
  aggregateId: string;
  aggregateType: string;
  state: any;
  version: number;
  timestamp: Date;
}

export class EventStore {
  private events: Event[] = [];
  private snapshots: Map<string, Snapshot> = new Map();
  private snapshotInterval = 10;

  async appendEvent(event: Omit<Event, 'id' | 'timestamp'>): Promise<Event> {
    const newEvent: Event = {
      ...event,
      id: this.generateId(),
      timestamp: new Date(),
    };

    this.events.push(newEvent);

    if (newEvent.version % this.snapshotInterval === 0) {
      await this.createSnapshot(newEvent.aggregateId, newEvent.aggregateType);
    }

    return newEvent;
  }

  async getEvents(
    aggregateId: string,
    fromVersion: number = 0
  ): Promise<Event[]> {
    return this.events.filter(
      (event) =>
        event.aggregateId === aggregateId && event.version > fromVersion
    );
  }

  async getEventsByType(
    aggregateType: string,
    eventType?: string
  ): Promise<Event[]> {
    return this.events.filter(
      (event) =>
        event.aggregateType === aggregateType &&
        (!eventType || event.eventType === eventType)
    );
  }

  async getSnapshot(aggregateId: string): Promise<Snapshot | null> {
    return this.snapshots.get(aggregateId) || null;
  }

  async createSnapshot(aggregateId: string, aggregateType: string): Promise<void> {
    const events = await this.getEvents(aggregateId);

    if (events.length === 0) return;

    const state = this.replayEvents(events);
    const lastEvent = events[events.length - 1];

    const snapshot: Snapshot = {
      aggregateId,
      aggregateType,
      state,
      version: lastEvent.version,
      timestamp: new Date(),
    };

    this.snapshots.set(aggregateId, snapshot);
  }

  async loadAggregate(aggregateId: string): Promise<any> {
    const snapshot = await this.getSnapshot(aggregateId);

    const fromVersion = snapshot ? snapshot.version : 0;
    const events = await this.getEvents(aggregateId, fromVersion);

    let state = snapshot ? snapshot.state : {};

    if (events.length > 0) {
      state = this.replayEvents(events, state);
    }

    return state;
  }

  private replayEvents(events: Event[], initialState: any = {}): any {
    return events.reduce((state, event) => {
      return this.applyEvent(state, event);
    }, initialState);
  }

  private applyEvent(state: any, event: Event): any {
    switch (event.eventType) {
      case 'UserCreated':
        return {
          ...state,
          id: event.aggregateId,
          ...event.data,
        };

      case 'UserUpdated':
        return {
          ...state,
          ...event.data,
        };

      case 'UserDeleted':
        return {
          ...state,
          deleted: true,
        };

      default:
        return state;
    }
  }

  private generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  async getEventStream(
    aggregateType?: string,
    fromTimestamp?: Date
  ): Promise<Event[]> {
    let filtered = this.events;

    if (aggregateType) {
      filtered = filtered.filter((e) => e.aggregateType === aggregateType);
    }

    if (fromTimestamp) {
      filtered = filtered.filter((e) => e.timestamp >= fromTimestamp);
    }

    return filtered;
  }
}

export class EventBus {
  private handlers: Map<string, Array<(event: Event) => void>> = new Map();

  subscribe(eventType: string, handler: (event: Event) => void): void {
    if (!this.handlers.has(eventType)) {
      this.handlers.set(eventType, []);
    }

    this.handlers.get(eventType)!.push(handler);
  }

  async publish(event: Event): Promise<void> {
    const handlers = this.handlers.get(event.eventType) || [];

    for (const handler of handlers) {
      await handler(event);
    }
  }
}
