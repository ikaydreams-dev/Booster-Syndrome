-- Seed file: Assign roles to users

-- Assign admin role to first user
INSERT INTO user_roles (user_id, role_id, assigned_at) VALUES
(1, 1, NOW()),  -- admin role
(2, 2, NOW()),  -- user role
(3, 2, NOW()),  -- user role
(4, 2, NOW()),  -- user role
(5, 3, NOW())   -- guest role
ON CONFLICT (user_id, role_id) DO NOTHING;
