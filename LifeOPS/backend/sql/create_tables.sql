-- LifeOPS Database Setup Script
-- Run this in pgAdmin, Supabase SQL Editor, or any PostgreSQL client

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Table 1: users
CREATE TABLE IF NOT EXISTS users (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email        VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name    VARCHAR(100) NOT NULL,
  role         VARCHAR(10)  NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Table 2: sessions
CREATE TABLE IF NOT EXISTS sessions (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  VARCHAR(255) NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_revoked  BOOLEAN     NOT NULL DEFAULT FALSE
);

-- Table 3: tasks
CREATE TABLE IF NOT EXISTS tasks (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title        VARCHAR(255) NOT NULL,
  description  TEXT,
  due_date     TIMESTAMPTZ,
  priority     VARCHAR(10) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low','medium','high','urgent')),
  status       VARCHAR(20) NOT NULL DEFAULT 'todo' CHECK (status IN ('todo','in_progress','completed')),
  tags         TEXT[]      NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 4: audit_logs
CREATE TABLE IF NOT EXISTS audit_logs (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id       UUID        NOT NULL REFERENCES users(id),
  action_type    VARCHAR(50) NOT NULL,
  target_user_id UUID,
  details        JSONB,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert demo users (passwords are bcrypt hashed)
-- user@lifeops.dev / User@1234
-- admin@lifeops.dev / Admin@1234
INSERT INTO users (email, password_hash, full_name, role) VALUES
  ('user@lifeops.dev',  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/Lewdyq1XmBBCq5Gim', 'Demo User',  'user'),
  ('admin@lifeops.dev', '$2b$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uX7HwFsN2', 'Admin User', 'admin')
ON CONFLICT (email) DO NOTHING;