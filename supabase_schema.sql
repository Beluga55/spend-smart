-- =====================================================
-- EXPENSE TRACKER SUPABASE SCHEMA
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- BACKUPS TABLE (for cloud backup/restore)
-- =====================================================
CREATE TABLE IF NOT EXISTS backups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- =====================================================
-- CATEGORIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  color BIGINT NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- EXPENSES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  date DATE NOT NULL,
  note TEXT,
  recurring_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- BUDGETS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL,
  limit_amount DECIMAL(10,2) NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, month, year, category_id)
);

-- =====================================================
-- SAVING GOALS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS saving_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  target_amount DECIMAL(10,2) NOT NULL,
  current_amount DECIMAL(10,2) DEFAULT 0,
  deadline DATE,
  icon_name TEXT NOT NULL,
  color BIGINT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- RECURRING EXPENSES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS recurring_expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  note TEXT,
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
  start_date DATE NOT NULL,
  end_date DATE,
  last_created DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR BETTER PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_recurring ON expenses(recurring_id);

CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);

CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_month_year ON budgets(year, month);

CREATE INDEX IF NOT EXISTS idx_saving_goals_user_id ON saving_goals(user_id);

CREATE INDEX IF NOT EXISTS idx_recurring_user_id ON recurring_expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_recurring_active ON recurring_expenses(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_recurring_due ON recurring_expenses(last_created, start_date) WHERE is_active = true;

-- =====================================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE backups ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE saving_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_expenses ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES - Users can only access their own data
-- =====================================================

-- Backups: users can only see/modify their own backup
DROP POLICY IF EXISTS "Users can manage own backup" ON backups;
CREATE POLICY "Users can manage own backup" ON backups
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Categories: users can only see/modify their own categories
DROP POLICY IF EXISTS "Users can manage own categories" ON categories;
CREATE POLICY "Users can manage own categories" ON categories
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Expenses: users can only see/modify their own expenses
DROP POLICY IF EXISTS "Users can manage own expenses" ON expenses;
CREATE POLICY "Users can manage own expenses" ON expenses
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Budgets: users can only see/modify their own budgets
DROP POLICY IF EXISTS "Users can manage own budgets" ON budgets;
CREATE POLICY "Users can manage own budgets" ON budgets
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Saving Goals: users can only see/modify their own goals
DROP POLICY IF EXISTS "Users can manage own saving goals" ON saving_goals;
CREATE POLICY "Users can manage own saving goals" ON saving_goals
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Recurring Expenses: users can only see/modify their own recurring
DROP POLICY IF EXISTS "Users can manage own recurring expenses" ON recurring_expenses;
CREATE POLICY "Users can manage own recurring expenses" ON recurring_expenses
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- FUNCTION: Auto-create default categories for new users
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert default categories for the new user
  INSERT INTO categories (user_id, name, icon_name, color, is_default)
  VALUES
    (NEW.id, 'Food', 'restaurant', 4294198070, true),
    (NEW.id, 'Transport', 'directions_car', 4280391411, true),
    (NEW.id, 'Shopping', 'shopping_bag', 4294959710, true),
    (NEW.id, 'Bills', 'receipt_long', 4282515283, true),
    (NEW.id, 'Entertainment', 'movie', 4289787567, true),
    (NEW.id, 'Health', 'medical_services', 4292466159, true),
    (NEW.id, 'Other', 'more_horiz', 4287954253, true);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create default categories when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- ANONYMOUS AUTH ENABLED (for guest users)
-- =====================================================
-- Note: Enable this in Supabase Dashboard:
-- Authentication → Providers → Anonymous Sign-ins → Enable

-- =====================================================
-- SAMPLE DATA (optional - uncomment to add sample data)
-- =====================================================
/*
-- After creating a user, you can insert sample data like this:
-- Note: This is for testing only. Remove in production.

INSERT INTO expenses (user_id, amount, category_id, date, note)
SELECT
  auth.uid(),
  25.50,
  (SELECT id FROM categories WHERE user_id = auth.uid() AND name = 'Food' LIMIT 1),
  CURRENT_DATE,
  'Lunch at restaurant'
WHERE auth.uid() IS NOT NULL;
*/

-- =====================================================
-- VERIFICATION QUERIES (run these to check setup)
-- =====================================================
/*
-- Check if tables were created:
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Check if RLS is enabled:
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- Check if triggers exist:
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public';
*/
