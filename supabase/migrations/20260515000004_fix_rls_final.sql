-- COMPLETE Fix: Drop ALL policies and recreate with NO recursion
-- Run this ENTIRE script in Supabase SQL Editor

-- 1. Drop ALL existing policies on all 5 tables
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT schemaname, tablename, policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename IN ('groups', 'group_members', 'group_expenses', 'group_expense_splits', 'group_expense_items')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- 2. groups: simple, no cross-references
CREATE POLICY "groups_select" ON groups
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "groups_insert" ON groups
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);

CREATE POLICY "groups_update" ON groups
  FOR UPDATE TO authenticated USING (auth.uid() = created_by);

CREATE POLICY "groups_delete" ON groups
  FOR DELETE TO authenticated USING (auth.uid() = created_by);

-- 3. group_members: no self-referencing, no groups cross-reference
CREATE POLICY "group_members_select" ON group_members
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "group_members_insert" ON group_members
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "group_members_update" ON group_members
  FOR UPDATE TO authenticated USING (user_id = auth.uid());

CREATE POLICY "group_members_delete" ON group_members
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- 4. group_expenses: only members and creators can access
CREATE POLICY "group_expenses_select" ON group_expenses
  FOR SELECT TO authenticated USING (
    paid_by_user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true)
  );

CREATE POLICY "group_expenses_insert" ON group_expenses
  FOR INSERT TO authenticated WITH CHECK (
    paid_by_user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true)
  );

CREATE POLICY "group_expenses_update" ON group_expenses
  FOR UPDATE TO authenticated USING (paid_by_user_id = auth.uid());

CREATE POLICY "group_expenses_delete" ON group_expenses
  FOR DELETE TO authenticated USING (paid_by_user_id = auth.uid());

-- 5. group_expense_splits: check via group_expenses (already verified above, no recursion since group_expenses doesn't reference group_expense_splits)
CREATE POLICY "group_expense_splits_select" ON group_expense_splits
  FOR SELECT TO authenticated USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_splits.group_expense_id AND (paid_by_user_id = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true)))
  );

CREATE POLICY "group_expense_splits_insert" ON group_expense_splits
  FOR INSERT TO authenticated WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_splits.group_expense_id AND (paid_by_user_id = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true)))
  );

CREATE POLICY "group_expense_splits_update" ON group_expense_splits
  FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- 6. group_expense_items: similar to splits
CREATE POLICY "group_expense_items_select" ON group_expense_items
  FOR SELECT TO authenticated USING (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_items.group_expense_id AND (paid_by_user_id = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true)))
  );

CREATE POLICY "group_expense_items_insert" ON group_expense_items
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_items.group_expense_id AND (paid_by_user_id = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true)))
  );

CREATE POLICY "group_expense_items_update" ON group_expense_items
  FOR UPDATE TO authenticated USING (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_items.group_expense_id AND (paid_by_user_id = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true)))
  );

CREATE POLICY "group_expense_items_delete" ON group_expense_items
  FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_items.group_expense_id AND (paid_by_user_id = auth.uid() OR EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true)))
  );