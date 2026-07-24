#!/bin/bash
set -e

echo "Seeding database..."

psql $DATABASE_URL << 'SQL'
-- Insert test users
INSERT INTO users (email, password_hash) VALUES
    ('admin@example.com', '$2a$12$example_hash_1'),
    ('user1@example.com', '$2a$12$example_hash_2'),
    ('user2@example.com', '$2a$12$example_hash_3')
ON CONFLICT (email) DO NOTHING;

-- Insert test posts
INSERT INTO posts (user_id, title, content, published) VALUES
    (1, 'Welcome Post', 'This is the first post', true),
    (2, 'Test Post', 'Testing the system', false)
ON CONFLICT DO NOTHING;

-- Insert test comments
INSERT INTO comments (post_id, user_id, content) VALUES
    (1, 2, 'Great post!'),
    (1, 3, 'Thanks for sharing')
ON CONFLICT DO NOTHING;
SQL

echo "Database seeded successfully!"
