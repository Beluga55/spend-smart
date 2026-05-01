-- =====================================================
-- PG_CRON SETUP FOR RECURRING EXPENSE PROCESSING
-- =====================================================
-- This schedules the Edge Function to run daily at midnight
--
-- IMPORTANT: Enable pg_cron extension first:
-- 1. Go to Supabase Dashboard → Database → Extensions
-- 2. Enable "pg_cron" extension
--
-- Then run this SQL to schedule the job
-- =====================================================

-- Enable pg_cron extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- Schedule the recurring expense processor to run daily at midnight
-- Replace 'YOUR_SERVICE_ROLE_KEY' with your actual service role key
-- You can find it at: Supabase Dashboard → Settings → API → service_role key

SELECT cron.schedule(
  'process-recurring-daily',
  '0 0 * * *',
  $$
  SELECT net.http_post(
    url:='https://your-project-id.supabase.co/functions/v1/process-recurring',
    headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
  );
  $$
);

-- =====================================================
-- TO UNSCHEDULE (if needed):
-- SELECT cron.unschedule('process-recurring-daily');
-- =====================================================

-- =====================================================
-- TO VIEW SCHEDULED JOBS:
-- SELECT * FROM cron.job;
-- =====================================================

-- =====================================================
-- MANUAL TEST (run this to test the edge function):
-- SELECT net.http_post(
--   url:='https://your-project-id.supabase.co/functions/v1/process-recurring',
--   headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
-- );
-- =====================================================
