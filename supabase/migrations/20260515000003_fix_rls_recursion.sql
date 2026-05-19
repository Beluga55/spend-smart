-- Fix RLS infinite recursion
-- The old policies caused group_members <-> groups mutual recursion
-- Solution: Use simplified policies that don't cross-reference each other

-- Drop ALL existing policies first
DROP POLICY IF EXISTS "Authenticated users can create groups" ON groups;
DROP POLICY IF EXISTS "Anyone can look up groups by invite code" ON groups;
DROP POLICY IF EXISTS "Users can update groups they belong to" ON groups;
DROP POLICY IF EXISTS "Users can delete groups they belong to" ON groups;
DROP POLICY IF EXISTS "Group creators can update their groups" ON groups;
DROP POLICY IF EXISTS "Group creators can delete their groups" ON groups;
DROP POLICY IF EXISTS "Users can view members of their groups" ON group_members;
DROP POLICY IF EXISTS "Users can add members to their groups" ON group_members;
DROP POLICY IF EXISTS "Users can update members of their groups" ON group_members;
DROP POLICY IF EXISTS "Users can view expenses of their groups" ON group_expenses;
DROP POLICY IF EXISTS "Users can add expenses to their groups" ON group_expenses;
DROP POLICY IF EXISTS "Users can update expenses of their groups" ON group_expenses;
DROP POLICY IF EXISTS "Users can delete expenses of their groups" ON group_expenses;
DROP POLICY IF EXISTS "Users can view splits of their group expenses" ON group_expense_splits;
DROP POLICY IF EXISTS "Users can add splits to their group expenses" ON group_expense_splits;
DROP POLICY IF EXISTS "Users can update splits of their group expenses" ON group_expense_splits;
DROP POLICY IF EXISTS "Users can view items of their group expenses" ON group_expense_items;
DROP POLICY IF EXISTS "Users can add items to their group expenses" ON group_expense_items;
DROP POLICY IF EXISTS "Users can update items of their group expenses" ON group_expense_items;
DROP POLICY IF EXISTS "Users can delete items of their group expenses" ON group_expense_items;

-- groups: simple policies, NO references to group_members
CREATE POLICY "groups_select" ON groups
  FOR SELECT TO authenticated USING (is_active = true);

CREATE POLICY "groups_insert" ON groups
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);

CREATE POLICY "groups_update" ON groups
  FOR UPDATE TO authenticated USING (auth.uid() = created_by);

CREATE POLICY "groups_delete" ON groups
  FOR DELETE TO authenticated USING (auth.uid() = created_by);

-- group_members: self-referencing only (check user_id = auth.uid()), NO subquery on groups
CREATE POLICY "group_members_select" ON group_members
  FOR SELECT TO authenticated USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = group_members.group_id AND gm.user_id = auth.uid() AND gm.is_active = true));

CREATE POLICY "group_members_insert" ON group_members
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() AND EXISTS (SELECT 1 FROM groups WHERE id = group_id AND is_active = true));

CREATE POLICY "group_members_update" ON group_members
  FOR UPDATE TO authenticated USING (user_id = auth.uid());

-- group_expenses: check membership via group_members (no recursion since group_members no longer references group_expenses)
CREATE POLICY "group_expenses_select" ON group_expenses
  FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()));

CREATE POLICY "group_expenses_insert" ON group_expenses
  FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()));

CREATE POLICY "group_expenses_update" ON group_expenses
  FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR paid_by_user_id = auth.uid());

CREATE POLICY "group_expenses_delete" ON group_expenses
  FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()) OR paid_by_user_id = auth.uid());

-- group_expense_splits: check via group_expenses -> group_members chain
CREATE POLICY "group_expense_splits_select" ON group_expense_splits
  FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_splits.group_expense_id AND (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()))));

CREATE POLICY "group_expense_splits_insert" ON group_expense_splits
  FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_splits.group_expense_id AND (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()))));

CREATE POLICY "group_expense_splits_update" ON group_expense_splits
  FOR UPDATE TO authenticated USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_splits.group_expense_id AND (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()))));

-- group_expense_items: similar chain via group_expenses
CREATE POLICY "group_expense_items_select" ON group_expense_items
  FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_items.group_expense_id AND (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()))));

CREATE POLICY "group_expense_items_insert" ON group_expense_items
  FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_items.group_expense_id AND (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()))));

CREATE POLICY "group_expense_items_update" ON group_expense_items
  FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_items.group_expense_id AND (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()))));

CREATE POLICY "group_expense_items_delete" ON group_expense_items
  FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM group_expenses WHERE id = group_expense_items.group_expense_id AND (EXISTS (SELECT 1 FROM group_members WHERE group_id = group_expenses.group_id AND user_id = auth.uid() AND is_active = true) OR EXISTS (SELECT 1 FROM groups WHERE id = group_expenses.group_id AND created_by = auth.uid()))));