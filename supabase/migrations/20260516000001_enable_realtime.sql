-- Enable Supabase Realtime for all group tables
-- This allows the app to receive WebSocket push notifications for changes.

ALTER PUBLICATION supabase_realtime ADD TABLE groups;
ALTER PUBLICATION supabase_realtime ADD TABLE group_members;
ALTER PUBLICATION supabase_realtime ADD TABLE group_expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE group_expense_splits;
ALTER PUBLICATION supabase_realtime ADD TABLE group_expense_items;