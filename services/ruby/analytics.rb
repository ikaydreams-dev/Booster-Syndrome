module Analytics
  class Event
    attr_reader :name, :properties, :timestamp, :user_id, :session_id

    def initialize(name, properties: {}, user_id: nil, session_id: nil)
      @name = name
      @properties = properties
      @timestamp = Time.now
      @user_id = user_id
      @session_id = session_id
    end

    def to_h
      {
        name: @name,
        properties: @properties,
        timestamp: @timestamp.iso8601,
        user_id: @user_id,
        session_id: @session_id
      }
    end
  end

  class Tracker
    def initialize
      @events = []
      @mutex = Mutex.new
    end

    def track(event_name, properties: {}, user_id: nil, session_id: nil)
      event = Event.new(event_name, properties: properties, user_id: user_id, session_id: session_id)

      @mutex.synchronize do
        @events << event
      end

      event
    end

    def page_view(page, properties: {}, user_id: nil, session_id: nil)
      track('page_view', properties: properties.merge(page: page), user_id: user_id, session_id: session_id)
    end

    def conversion(goal, value: nil, properties: {}, user_id: nil, session_id: nil)
      track('conversion', properties: properties.merge(goal: goal, value: value), user_id: user_id, session_id: session_id)
    end

    def events(filters: {})
      @mutex.synchronize do
        filtered = @events

        if filters[:name]
          filtered = filtered.select { |e| e.name == filters[:name] }
        end

        if filters[:user_id]
          filtered = filtered.select { |e| e.user_id == filters[:user_id] }
        end

        if filters[:session_id]
          filtered = filtered.select { |e| e.session_id == filters[:session_id] }
        end

        if filters[:start_time]
          filtered = filtered.select { |e| e.timestamp >= filters[:start_time] }
        end

        if filters[:end_time]
          filtered = filtered.select { |e| e.timestamp <= filters[:end_time] }
        end

        filtered
      end
    end

    def clear
      @mutex.synchronize do
        @events.clear
      end
    end
  end

  class Aggregator
    def initialize(tracker)
      @tracker = tracker
    end

    def count(event_name, filters: {})
      events = @tracker.events(filters: filters.merge(name: event_name))
      events.size
    end

    def unique_users(event_name, filters: {})
      events = @tracker.events(filters: filters.merge(name: event_name))
      events.map(&:user_id).compact.uniq.size
    end

    def group_by_property(event_name, property, filters: {})
      events = @tracker.events(filters: filters.merge(name: event_name))

      grouped = Hash.new(0)

      events.each do |event|
        value = event.properties[property]
        grouped[value] += 1 if value
      end

      grouped
    end

    def time_series(event_name, interval: :hour, filters: {})
      events = @tracker.events(filters: filters.merge(name: event_name))

      series = Hash.new(0)

      events.each do |event|
        bucket = time_bucket(event.timestamp, interval)
        series[bucket] += 1
      end

      series.sort.to_h
    end

    def funnel(steps)
      results = steps.map do |step|
        count = @tracker.events(filters: { name: step }).size
        { step: step, count: count }
      end

      results.each_with_index do |result, index|
        if index > 0
          previous_count = results[index - 1][:count]
          result[:conversion_rate] = previous_count > 0 ? (result[:count] / previous_count.to_f) : 0
        end
      end

      results
    end

    def cohort_analysis(start_date, end_date, cohort_event, return_event)
      cohorts = Hash.new { |h, k| h[k] = Set.new }

      start_events = @tracker.events(
        filters: {
          name: cohort_event,
          start_time: start_date,
          end_time: end_date
        }
      )

      start_events.each do |event|
        cohort_date = event.timestamp.to_date
        cohorts[cohort_date] << event.user_id
      end

      retention = {}

      cohorts.each do |cohort_date, user_ids|
        retention[cohort_date] = {}

        (0..30).each do |day|
          check_date = cohort_date + day
          returned = user_ids.count do |user_id|
            @tracker.events(
              filters: {
                name: return_event,
                user_id: user_id,
                start_time: check_date,
                end_time: check_date + 1
              }
            ).any?
          end

          retention[cohort_date][day] = {
            count: returned,
            rate: user_ids.size > 0 ? (returned / user_ids.size.to_f) : 0
          }
        end
      end

      retention
    end

    private

    def time_bucket(timestamp, interval)
      case interval
      when :minute
        timestamp.strftime('%Y-%m-%d %H:%M')
      when :hour
        timestamp.strftime('%Y-%m-%d %H:00')
      when :day
        timestamp.strftime('%Y-%m-%d')
      when :week
        timestamp.strftime('%Y-W%U')
      when :month
        timestamp.strftime('%Y-%m')
      else
        timestamp.to_s
      end
    end
  end

  class SessionAnalyzer
    def initialize(tracker, timeout: 1800)
      @tracker = tracker
      @timeout = timeout
    end

    def sessions
      events = @tracker.events(filters: {}).sort_by(&:timestamp)
      sessions = []
      current_session = []
      last_event_time = nil

      events.each do |event|
        if last_event_time && (event.timestamp - last_event_time) > @timeout
          sessions << current_session unless current_session.empty?
          current_session = []
        end

        current_session << event
        last_event_time = event.timestamp
      end

      sessions << current_session unless current_session.empty?
      sessions
    end

    def average_session_duration
      session_list = sessions
      return 0 if session_list.empty?

      total_duration = session_list.sum do |session|
        next 0 if session.size < 2
        session.last.timestamp - session.first.timestamp
      end

      total_duration / session_list.size.to_f
    end

    def bounce_rate
      session_list = sessions
      return 0 if session_list.empty?

      bounced = session_list.count { |session| session.size == 1 }
      bounced / session_list.size.to_f
    end

    def pages_per_session
      session_list = sessions
      return 0 if session_list.empty?

      total_pages = session_list.sum { |session| session.count { |e| e.name == 'page_view' } }
      total_pages / session_list.size.to_f
    end
  end

  class ABTestAnalyzer
    def initialize(tracker)
      @tracker = tracker
    end

    def analyze(test_name, control_variant, test_variant, conversion_event)
      control_users = users_in_variant(test_name, control_variant)
      test_users = users_in_variant(test_name, test_variant)

      control_conversions = conversions_for_users(control_users, conversion_event)
      test_conversions = conversions_for_users(test_users, conversion_event)

      control_rate = control_users.size > 0 ? control_conversions / control_users.size.to_f : 0
      test_rate = test_users.size > 0 ? test_conversions / test_users.size.to_f : 0

      {
        control: {
          users: control_users.size,
          conversions: control_conversions,
          rate: control_rate
        },
        test: {
          users: test_users.size,
          conversions: test_conversions,
          rate: test_rate
        },
        improvement: control_rate > 0 ? ((test_rate - control_rate) / control_rate) : 0,
        winner: test_rate > control_rate ? test_variant : control_variant
      }
    end

    private

    def users_in_variant(test_name, variant)
      events = @tracker.events(filters: { name: 'ab_test_assignment' })
      events.select do |e|
        e.properties[:test_name] == test_name && e.properties[:variant] == variant
      end.map(&:user_id).compact.uniq
    end

    def conversions_for_users(user_ids, conversion_event)
      user_ids.count do |user_id|
        @tracker.events(filters: { name: conversion_event, user_id: user_id }).any?
      end
    end
  end

  class Dashboard
    def initialize(tracker)
      @tracker = tracker
      @aggregator = Aggregator.new(tracker)
      @session_analyzer = SessionAnalyzer.new(tracker)
    end

    def overview(start_time: nil, end_time: nil)
      filters = {}
      filters[:start_time] = start_time if start_time
      filters[:end_time] = end_time if end_time

      {
        total_events: @tracker.events(filters: filters).size,
        unique_users: @tracker.events(filters: filters).map(&:user_id).compact.uniq.size,
        page_views: @aggregator.count('page_view', filters: filters),
        conversions: @aggregator.count('conversion', filters: filters),
        avg_session_duration: @session_analyzer.average_session_duration,
        bounce_rate: @session_analyzer.bounce_rate,
        pages_per_session: @session_analyzer.pages_per_session
      }
    end

    def top_pages(limit: 10, filters: {})
      @aggregator.group_by_property('page_view', :page, filters: filters)
                 .sort_by { |_, count| -count }
                 .take(limit)
                 .to_h
    end

    def conversion_rate(goal, filters: {})
      total_users = @tracker.events(filters: filters).map(&:user_id).compact.uniq.size
      converted_users = @tracker.events(filters: filters.merge(name: 'conversion'))
                                .select { |e| e.properties[:goal] == goal }
                                .map(&:user_id)
                                .compact
                                .uniq
                                .size

      total_users > 0 ? converted_users / total_users.to_f : 0
    end
  end
end
