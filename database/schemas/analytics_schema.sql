-- Analytics Database Schema
-- PostgreSQL

CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE analytics.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    session_id UUID,
    event_type VARCHAR(100) NOT NULL,
    event_name VARCHAR(255) NOT NULL,
    properties JSONB,
    page_url TEXT,
    referrer TEXT,
    user_agent TEXT,
    ip_address INET,
    country VARCHAR(100),
    city VARCHAR(100),
    device_type VARCHAR(50),
    browser VARCHAR(100),
    os VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_events_user_id (user_id),
    INDEX idx_events_session_id (session_id),
    INDEX idx_events_event_type (event_type),
    INDEX idx_events_created_at (created_at DESC),
    INDEX idx_events_country (country),
    INDEX idx_events_properties USING GIN (properties)
) PARTITION BY RANGE (created_at);

CREATE TABLE analytics.events_2024_01 PARTITION OF analytics.events
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE analytics.events_2024_02 PARTITION OF analytics.events
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE analytics.funnels (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    steps JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE analytics.cohorts (
    id SERIAL PRIMARY KEY,
    cohort_date DATE NOT NULL,
    user_count INTEGER NOT NULL,
    retention_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_cohorts_date (cohort_date)
);

CREATE TABLE analytics.daily_metrics (
    metric_date DATE PRIMARY KEY,
    dau INTEGER,
    mau INTEGER,
    total_events BIGINT,
    unique_sessions INTEGER,
    avg_session_duration INTERVAL,
    top_events JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE MATERIALIZED VIEW analytics.event_summary AS
SELECT
    event_type,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    DATE_TRUNC('day', created_at) as event_date
FROM analytics.events
GROUP BY event_type, DATE_TRUNC('day', created_at);

CREATE INDEX ON analytics.event_summary (event_type, event_date);

CREATE OR REPLACE FUNCTION analytics.calculate_retention(
    cohort_date DATE,
    days INTEGER
) RETURNS TABLE (
    day INTEGER,
    active_users INTEGER,
    retention_rate NUMERIC
) AS $$
DECLARE
    cohort_users UUID[];
BEGIN
    SELECT ARRAY_AGG(DISTINCT user_id)
    INTO cohort_users
    FROM analytics.events
    WHERE DATE(created_at) = cohort_date
    AND event_type = 'signup';

    RETURN QUERY
    SELECT
        (DATE(e.created_at) - cohort_date)::INTEGER as day,
        COUNT(DISTINCT e.user_id)::INTEGER as active_users,
        ROUND((COUNT(DISTINCT e.user_id)::NUMERIC / ARRAY_LENGTH(cohort_users, 1)) * 100, 2) as retention_rate
    FROM analytics.events e
    WHERE e.user_id = ANY(cohort_users)
    AND DATE(e.created_at) BETWEEN cohort_date AND (cohort_date + days)
    GROUP BY DATE(e.created_at)
    ORDER BY day;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION analytics.track_event(
    p_user_id UUID,
    p_event_type VARCHAR,
    p_event_name VARCHAR,
    p_properties JSONB DEFAULT '{}'::JSONB
) RETURNS UUID AS $$
DECLARE
    event_id UUID;
BEGIN
    INSERT INTO analytics.events (user_id, event_type, event_name, properties)
    VALUES (p_user_id, p_event_type, p_event_name, p_properties)
    RETURNING id INTO event_id;

    RETURN event_id;
END;
$$ LANGUAGE plpgsql;
