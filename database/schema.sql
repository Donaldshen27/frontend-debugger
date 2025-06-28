-- Frontend Debugger Database Schema
-- PostgreSQL database for tracking automated frontend testing sessions

-- Drop existing tables if they exist
DROP TABLE IF EXISTS issues CASCADE;
DROP TABLE IF EXISTS pages CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;

-- Sessions table - tracks overall debugging sessions
CREATE TABLE sessions (
  id SERIAL PRIMARY KEY,
  started_at TIMESTAMP NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMP,
  target_url TEXT NOT NULL,
  git_commit_hash VARCHAR(40),
  total_pages INTEGER DEFAULT 0,
  completed_pages INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'running' CHECK (status IN ('running', 'complete', 'failed', 'paused'))
);

-- Pages table - tracks individual page testing progress
CREATE TABLE pages (
  id SERIAL PRIMARY KEY,
  session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'testing', 'complete', 'failed')),
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  token_count INTEGER DEFAULT 0,
  screenshot_path TEXT,
  UNIQUE(session_id, url)
);

-- Issues table - stores all discovered issues
CREATE TABLE issues (
  id SERIAL PRIMARY KEY,
  session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  page_url TEXT NOT NULL,
  severity VARCHAR(10) NOT NULL CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
  description TEXT NOT NULL,
  screenshot_path TEXT,
  reproduction_steps TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_started_at ON sessions(started_at DESC);
CREATE INDEX idx_pages_session_id ON pages(session_id);
CREATE INDEX idx_pages_status ON pages(status);
CREATE INDEX idx_issues_session_id ON issues(session_id);
CREATE INDEX idx_issues_severity ON issues(severity);
CREATE INDEX idx_issues_page_url ON issues(page_url);

-- Create a view for session summary
CREATE VIEW session_summary AS
SELECT 
  s.id,
  s.started_at,
  s.completed_at,
  s.target_url,
  s.status,
  COUNT(DISTINCT p.id) as total_pages,
  COUNT(DISTINCT CASE WHEN p.status = 'complete' THEN p.id END) as completed_pages,
  COUNT(DISTINCT i.id) as total_issues,
  COUNT(DISTINCT CASE WHEN i.severity = 'CRITICAL' THEN i.id END) as critical_issues,
  COUNT(DISTINCT CASE WHEN i.severity = 'HIGH' THEN i.id END) as high_issues,
  COUNT(DISTINCT CASE WHEN i.severity = 'MEDIUM' THEN i.id END) as medium_issues,
  COUNT(DISTINCT CASE WHEN i.severity = 'LOW' THEN i.id END) as low_issues,
  SUM(p.token_count) as total_tokens_used
FROM sessions s
LEFT JOIN pages p ON s.id = p.session_id
LEFT JOIN issues i ON s.id = i.session_id
GROUP BY s.id;

-- Function to update session stats
CREATE OR REPLACE FUNCTION update_session_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE sessions
  SET 
    total_pages = (SELECT COUNT(*) FROM pages WHERE session_id = NEW.session_id),
    completed_pages = (SELECT COUNT(*) FROM pages WHERE session_id = NEW.session_id AND status = 'complete')
  WHERE id = NEW.session_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update session stats when pages are updated
CREATE TRIGGER update_session_stats_trigger
AFTER INSERT OR UPDATE ON pages
FOR EACH ROW
EXECUTE FUNCTION update_session_stats();

-- Sample data for testing (commented out)
/*
INSERT INTO sessions (target_url) VALUES ('https://example.com');
INSERT INTO pages (session_id, url, status) VALUES 
  (1, 'https://example.com', 'complete'),
  (1, 'https://example.com/about', 'testing'),
  (1, 'https://example.com/contact', 'pending');
INSERT INTO issues (session_id, page_url, severity, description) VALUES
  (1, 'https://example.com', 'HIGH', 'Submit button not working on mobile'),
  (1, 'https://example.com/about', 'LOW', 'Text overflow in header');
*/