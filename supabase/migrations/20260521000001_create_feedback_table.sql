-- Create feedback table for user bug reports and feature requests
-- This table stores user feedback submitted from the app settings

-- Create the feedback table
CREATE TABLE IF NOT EXISTS feedback (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('bug_report', 'feature_request')),
  message TEXT NOT NULL,
  app_version TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient user feedback queries
CREATE INDEX IF NOT EXISTS idx_feedback_user_id ON feedback(user_id);

-- Enable RLS for security
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- RLS policy: users can only access their own feedback
DROP POLICY IF EXISTS "Users can manage own feedback" ON feedback;
CREATE POLICY "Users can manage own feedback" ON feedback
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
