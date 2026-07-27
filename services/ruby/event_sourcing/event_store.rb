module EventSourcing
  class Event
    attr_reader :aggregate_id, :type, :data, :metadata, :timestamp, :version

    def initialize(aggregate_id:, type:, data:, metadata: {}, version: 1)
      @aggregate_id = aggregate_id
      @type = type
      @data = data
      @metadata = metadata
      @timestamp = Time.now
      @version = version
    end

    def to_h
      {
        aggregate_id: @aggregate_id,
        type: @type,
        data: @data,
        metadata: @metadata,
        timestamp: @timestamp,
        version: @version
      }
    end
  end

  class EventStore
    def initialize
      @events = []
      @snapshots = {}
    end

    def append(event)
      @events << event
      publish_event(event)
    end

    def get_events(aggregate_id, from_version: 0)
      @events.select do |event|
        event.aggregate_id == aggregate_id && event.version > from_version
      end
    end

    def get_all_events(from: 0, to: nil)
      events = @events[from..-1] || []
      to ? events[0...to] : events
    end

    def create_snapshot(aggregate_id, state, version)
      @snapshots[aggregate_id] = {
        state: state,
        version: version,
        timestamp: Time.now
      }
    end

    def get_snapshot(aggregate_id)
      @snapshots[aggregate_id]
    end

    def replay(aggregate_id)
      snapshot = get_snapshot(aggregate_id)
      
      if snapshot
        state = snapshot[:state]
        from_version = snapshot[:version]
      else
        state = {}
        from_version = 0
      end

      events = get_events(aggregate_id, from_version: from_version)
      
      events.each do |event|
        state = apply_event(state, event)
      end

      state
    end

    private

    def apply_event(state, event)
      case event.type
      when 'user_created'
        state.merge(event.data)
      when 'user_updated'
        state.merge(event.data)
      when 'post_created'
        state[:posts] ||= []
        state[:posts] << event.data
        state
      else
        state
      end
    end

    def publish_event(event)
      # Publish to event bus for subscribers
      puts "Event published: #{event.type} for #{event.aggregate_id}"
    end
  end

  class AggregateRoot
    attr_reader :id, :version, :uncommitted_events

    def initialize(id)
      @id = id
      @version = 0
      @uncommitted_events = []
    end

    def apply_event(event)
      @uncommitted_events << event
      @version += 1
    end

    def commit_events(event_store)
      @uncommitted_events.each do |event|
        event_store.append(event)
      end
      @uncommitted_events.clear
    end

    def load_from_history(events)
      events.each do |event|
        apply(event)
        @version = event.version
      end
    end

    protected

    def apply(event)
      # Override in subclasses
    end
  end
end
