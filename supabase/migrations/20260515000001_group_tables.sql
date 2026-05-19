-- Group Bill-Splitting Tables
-- Run this in your Supabase SQL Editor

-- groups
CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  invite_code TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- group_members
CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users,
  display_name TEXT NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT now(),
  role TEXT DEFAULT 'member',
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(group_id, user_id)
);

-- group_expenses
CREATE TABLE IF NOT EXISTS group_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  total_amount NUMERIC NOT NULL,
  date DATE NOT NULL,
  paid_by_user_id UUID REFERENCES auth.users NOT NULL,
  receipt_image_path TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- group_expense_splits
CREATE TABLE IF NOT EXISTS group_expense_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_expense_id UUID REFERENCES group_expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users NOT NULL,
  amount NUMERIC NOT NULL,
  is_settled BOOLEAN DEFAULT false,
  settled_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- group_expense_items
CREATE TABLE IF NOT EXISTS group_expense_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_expense_id UUID REFERENCES group_expenses(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  assigned_to_user_ids UUID[] NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_expenses_group_id ON group_expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_group_expense_splits_expense_id ON group_expense_splits(group_expense_id);
CREATE INDEX IF NOT EXISTS idx_group_expense_splits_user_id ON group_expense_splits(user_id);
CREATE INDEX IF NOT EXISTS idx_group_expense_items_expense_id ON group_expense_items(group_expense_id);
CREATE INDEX IF NOT EXISTS idx_groups_invite_code ON groups(invite_code);
CREATE INDEX IF NOT EXISTS idx_groups_is_active ON groups(is_active);

-- Enable RLS
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_expense_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can read/write data for groups they are members of

-- Groups: anyone authenticated can create; anyone can look up by invite code; members can read full details; creators can update/delete
CREATE POLICY "Authenticated users can create groups" ON groups
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Anyone can look up groups by invite code" ON groups
  FOR SELECT TO authenticated USING (is_active = true);

CREATE POLICY "Users can update groups they belong to" ON groups
  FOR UPDATE TO authenticated USING (
    created_by = auth.uid() OR
    EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND role = 'admin' AND is_active = true)
  );

CREATE POLICY "Users can delete groups they belong to" ON groups
  FOR DELETE TO authenticated USING (
    created_by = auth.uid() OR
    EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND role = 'admin' AND is_active = true)
  );

-- Group Members
CREATE POLICY "Users can view members of their groups" ON group_members
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = group_id AND gm.user_id = auth.uid() AND gm.is_active = true)))
  );

CREATE POLICY "Users can add members to their groups" ON group_members
  FOR INSERT TO authenticated WITH CHECK (
    -- Allow joining by invite: user_id must be auth.uid() or null
    (user_id = auth.uid()) AND
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND is_active = true)
  );

CREATE POLICY "Users can update members of their groups" ON group_members
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = group_id AND gm.user_id = auth.uid() AND gm.role = 'admin' AND gm.is_active = true)))
  );

-- Group Expenses
CREATE POLICY "Users can view expenses of their groups" ON group_expenses
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_id AND user_id = auth.uid() AND is_active = true)))
  );

CREATE POLICY "Users can add expenses to their groups" ON group_expenses
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_id AND user_id = auth.uid() AND is_active = true)))
  );

CREATE POLICY "Users can update expenses of their groups" ON group_expenses
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_id AND user_id = auth.uid() AND is_active = true)))
  );

CREATE POLICY "Users can delete expenses of their groups" ON group_expenses
  FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_id AND user_id = auth.uid() AND is_active = true)))
  );

-- Group Expense Splits
CREATE POLICY "Users can view splits of their group expenses" ON group_expense_splits
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_id AND EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND is_active = true))))
  );

CREATE POLICY "Users can add splits to their group expenses" ON group_expense_splits
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_id AND EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND is_active = true))))
  );

CREATE POLICY "Users can update splits of their group expenses" ON group_expense_splits
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_id AND EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND is_active = true))))
  );

-- Group Expense Items
CREATE POLICY "Users can view items of their group expenses" ON group_expense_items
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_id AND EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND is_active = true))))
  );

CREATE POLICY "Users can add items to their group expenses" ON group_expense_items
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_id AND EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND is_active = true))))
  );

CREATE POLICY "Users can update items of their group expenses" ON group_expense_items
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_id AND EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND is_active = true))))
  );

CREATE POLICY "Users can delete items of their group expenses" ON group_expense_items
  FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_id AND EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND (created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = groups.id AND user_id = auth.uid() AND is_active = true))))
  );