-- Seed file: Insert test posts

INSERT INTO posts (user_id, title, content, published, created_at, updated_at) VALUES
(1, 'Welcome to Booster Syndrome', 'This is our first blog post about building microservices across multiple languages.', true, NOW(), NOW()),
(1, 'Multi-language Architecture', 'Exploring the benefits and challenges of polyglot programming.', true, NOW(), NOW()),
(2, 'Ruby Best Practices', 'Tips and tricks for writing clean Ruby code.', true, NOW(), NOW()),
(2, 'Python for Data Science', 'Getting started with NumPy and Pandas.', false, NOW(), NOW()),
(3, 'Go Concurrency Patterns', 'Understanding goroutines and channels.', true, NOW(), NOW()),
(3, 'Rust Memory Safety', 'How Rust prevents common memory bugs.', true, NOW(), NOW()),
(4, 'Draft Post', 'This post is not yet published.', false, NOW(), NOW())
ON CONFLICT DO NOTHING;
