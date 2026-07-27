-- Seed file: Insert test users

INSERT INTO users (email, password_hash, created_at, updated_at) VALUES
('admin@booster.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIiIUOJqHK', NOW(), NOW()),
('user1@booster.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIiIUOJqHK', NOW(), NOW()),
('user2@booster.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIiIUOJqHK', NOW(), NOW()),
('user3@booster.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIiIUOJqHK', NOW(), NOW()),
('user4@booster.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIiIUOJqHK', NOW(), NOW())
ON CONFLICT (email) DO NOTHING;
