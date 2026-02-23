-- ============================================================
-- LifeOPS Database Setup Script (FIXED)
-- Group 5 | Spring 2025 | CSC 4350/6350
-- ============================================================

-- ── TABLE 1: users ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name     VARCHAR(100)  NOT NULL,
    email         VARCHAR(255)  NOT NULL UNIQUE,
    password_hash TEXT          NOT NULL,
    role          VARCHAR(20)   NOT NULL DEFAULT 'user'
                    CHECK (role IN ('user', 'admin')),
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ── TABLE 2: sessions ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS sessions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash    TEXT          NOT NULL,
    is_revoked    BOOLEAN       NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    expires_at    TIMESTAMPTZ   NOT NULL
);

-- ── TABLE 3: tasks ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tasks (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title         VARCHAR(255)  NOT NULL,
    description   TEXT,
    priority      VARCHAR(10)   NOT NULL DEFAULT 'medium'
                    CHECK (priority IN ('low', 'medium', 'high')),
    is_completed  BOOLEAN       NOT NULL DEFAULT FALSE,
    due_date      TIMESTAMPTZ,
    project_name  VARCHAR(100),
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ── TABLE 4: audit_logs ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id        UUID          NOT NULL REFERENCES users(id),
    action_type     VARCHAR(50)   NOT NULL
                      CHECK (action_type IN (
                        'LOGIN', 'LOGOUT', 'VIEW_USERS',
                        'SUSPEND_USER', 'REACTIVATE_USER',
                        'DELETE_USER', 'PROMOTE_USER',
                        'DEMOTE_USER', 'RESET_PASSWORD'
                      )),
    target_user_id  UUID          REFERENCES users(id),
    details         JSONB,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ── TABLE 5: habits ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS habits (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name             VARCHAR(100) NOT NULL,
    frequency        VARCHAR(20)  NOT NULL DEFAULT 'daily'
                       CHECK (frequency IN ('daily', 'weekly')),
    streak           INTEGER      NOT NULL DEFAULT 0,
    freeze_days_used INTEGER      NOT NULL DEFAULT 0 CHECK (freeze_days_used <= 2),
    last_completed   DATE,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── TABLE 6: focus_sessions ─────────────────────────────────
CREATE TABLE IF NOT EXISTS focus_sessions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal          TEXT          NOT NULL,
    duration_mins INTEGER       NOT NULL,
    session_type  VARCHAR(20)   NOT NULL DEFAULT 'pomodoro'
                    CHECK (session_type IN ('pomodoro', 'deep', 'custom')),
    outcome       VARCHAR(20)   NOT NULL DEFAULT 'done'
                    CHECK (outcome IN ('done', 'continue', 'stuck')),
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_tasks_user_id    ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_admin_id   ON audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_habits_user_id   ON habits(user_id);
CREATE INDEX IF NOT EXISTS idx_focus_user_id    ON focus_sessions(user_id);

-- ============================================================
-- SEED DATA
-- ============================================================

-- Insert users one by one (avoids UNION type conflicts)
INSERT INTO users (full_name, email, password_hash, role) VALUES
  ('Demo User',       'user@lifeops.dev',   '$2b$12$abc123hashedUserPassword',   'user'),
  ('Admin User',      'admin@lifeops.dev',  '$2b$12$abc123hashedAdminPassword',  'admin'),
  ('Bhuvan Karuturi', 'bhuvan@lifeops.dev', '$2b$12$abc123hashedBhuvanPassword', 'user'),
  ('John Dang',       'john@lifeops.dev',   '$2b$12$abc123hashedJohnPassword',   'user'),
  ('Aayush Kumar',    'aayush@lifeops.dev', '$2b$12$abc123hashedAayushPassword', 'user'),
  ('Aditya Sule',     'aditya@lifeops.dev', '$2b$12$abc123hashedAdityaPassword', 'user');

-- Insert tasks (using subqueries instead of UNION ALL)
INSERT INTO tasks (user_id, title, priority, is_completed, due_date, project_name)
VALUES (
  (SELECT id FROM users WHERE email = 'user@lifeops.dev'),
  'Design mockups', 'high', FALSE, NOW(), 'Website Redesign'
);
INSERT INTO tasks (user_id, title, priority, is_completed, due_date, project_name)
VALUES (
  (SELECT id FROM users WHERE email = 'user@lifeops.dev'),
  'Review feedback', 'medium', TRUE, NOW(), 'Website Redesign'
);
INSERT INTO tasks (user_id, title, priority, is_completed, due_date, project_name)
VALUES (
  (SELECT id FROM users WHERE email = 'user@lifeops.dev'),
  'Create content calendar', 'high', FALSE, NOW() + INTERVAL '1 day', 'Marketing Campaign'
);
INSERT INTO tasks (user_id, title, priority, is_completed, due_date, project_name)
VALUES (
  (SELECT id FROM users WHERE email = 'user@lifeops.dev'),
  'Read 30 pages', 'low', FALSE, NOW(), 'Personal Development'
);
INSERT INTO tasks (user_id, title, priority, is_completed, due_date, project_name)
VALUES (
  (SELECT id FROM users WHERE email = 'bhuvan@lifeops.dev'),
  'Write Sprint 2 report', 'high', FALSE, NOW() + INTERVAL '2 days', 'CSC 4350 Project'
);
INSERT INTO tasks (user_id, title, priority, is_completed, due_date, project_name)
VALUES (
  (SELECT id FROM users WHERE email = 'john@lifeops.dev'),
  'Setup GitHub repository', 'medium', TRUE, NOW(), 'CSC 4350 Project'
);

-- Insert habits
INSERT INTO habits (user_id, name, frequency, streak, freeze_days_used) VALUES
  ((SELECT id FROM users WHERE email = 'user@lifeops.dev'), 'Morning Exercise', 'daily', 5, 0),
  ((SELECT id FROM users WHERE email = 'user@lifeops.dev'), 'Read 30 minutes',  'daily', 3, 1),
  ((SELECT id FROM users WHERE email = 'user@lifeops.dev'), 'Meditation',       'daily', 7, 0),
  ((SELECT id FROM users WHERE email = 'bhuvan@lifeops.dev'), 'Daily Coding',   'daily', 12, 0),
  ((SELECT id FROM users WHERE email = 'john@lifeops.dev'),   'Evening Run',    'daily', 4,  0);

-- Insert focus sessions
INSERT INTO focus_sessions (user_id, goal, duration_mins, session_type, outcome) VALUES
  ((SELECT id FROM users WHERE email = 'user@lifeops.dev'), 'Complete design mockups',   25, 'pomodoro', 'done'),
  ((SELECT id FROM users WHERE email = 'user@lifeops.dev'), 'Review all project tasks',  60, 'deep',     'continue'),
  ((SELECT id FROM users WHERE email = 'user@lifeops.dev'), 'Study for exam',            25, 'pomodoro', 'done'),
  ((SELECT id FROM users WHERE email = 'bhuvan@lifeops.dev'),'Write backend auth code',  60, 'deep',     'done'),
  ((SELECT id FROM users WHERE email = 'john@lifeops.dev'),  'Setup Supabase database',  25, 'pomodoro', 'done');

-- Insert audit logs
INSERT INTO audit_logs (admin_id, action_type, target_user_id, details) VALUES
  (
    (SELECT id FROM users WHERE email = 'admin@lifeops.dev'),
    'LOGIN', NULL,
    '{"details": "Admin logged in successfully"}'::jsonb
  );
INSERT INTO audit_logs (admin_id, action_type, target_user_id, details) VALUES
  (
    (SELECT id FROM users WHERE email = 'admin@lifeops.dev'),
    'VIEW_USERS', NULL,
    '{"details": "Viewed user management panel"}'::jsonb
  );
INSERT INTO audit_logs (admin_id, action_type, target_user_id, details) VALUES
  (
    (SELECT id FROM users WHERE email = 'admin@lifeops.dev'),
    'SUSPEND_USER',
    (SELECT id FROM users WHERE email = 'john@lifeops.dev'),
    '{"details": "Account suspended for testing", "target_email": "john@lifeops.dev"}'::jsonb
  );
INSERT INTO audit_logs (admin_id, action_type, target_user_id, details) VALUES
  (
    (SELECT id FROM users WHERE email = 'admin@lifeops.dev'),
    'PROMOTE_USER',
    (SELECT id FROM users WHERE email = 'bhuvan@lifeops.dev'),
    '{"details": "Role promoted to admin", "target_email": "bhuvan@lifeops.dev"}'::jsonb
  );

-- ============================================================
-- SUCCESS! LifeOPS database is ready with 6 tables + sample data
-- Tables: users, sessions, tasks, audit_logs, habits, focus_sessions
-- ============================================================