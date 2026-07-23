-- Seed data: Sample analytics events for testing
-- Created: 2024-01-15

INSERT INTO events (user_id, event_type, event_name, properties, page_url, device_type, browser, os, country) VALUES
(gen_random_uuid(), 'page_view', 'home_page_viewed', '{"source": "organic"}', '/home', 'desktop', 'Chrome', 'macOS', 'US'),
(gen_random_uuid(), 'page_view', 'product_page_viewed', '{"product_id": "123", "category": "electronics"}', '/products/123', 'mobile', 'Safari', 'iOS', 'US'),
(gen_random_uuid(), 'click', 'button_clicked', '{"button_id": "cta-signup", "position": "header"}', '/home', 'desktop', 'Firefox', 'Windows', 'UK'),
(gen_random_uuid(), 'form_submit', 'signup_form_submitted', '{"plan": "premium", "source": "landing_page"}', '/signup', 'desktop', 'Chrome', 'macOS', 'CA'),
(gen_random_uuid(), 'purchase', 'order_completed', '{"order_id": "ORD-001", "amount": 99.99, "currency": "USD"}', '/checkout/success', 'mobile', 'Chrome', 'Android', 'US'),
(gen_random_uuid(), 'page_view', 'dashboard_viewed', '{"section": "overview"}', '/dashboard', 'desktop', 'Edge', 'Windows', 'DE'),
(gen_random_uuid(), 'click', 'share_button_clicked', '{"social_network": "twitter", "content_type": "article"}', '/blog/post-1', 'mobile', 'Safari', 'iOS', 'FR'),
(gen_random_uuid(), 'video_play', 'video_started', '{"video_id": "vid-456", "duration": 180}', '/videos/456', 'desktop', 'Chrome', 'macOS', 'JP'),
(gen_random_uuid(), 'search', 'search_performed', '{"query": "wireless headphones", "results_count": 42}', '/search', 'mobile', 'Chrome', 'Android', 'IN'),
(gen_random_uuid(), 'error', 'api_error', '{"endpoint": "/api/users", "status_code": 500}', '/dashboard', 'desktop', 'Chrome', 'Linux', 'BR');
