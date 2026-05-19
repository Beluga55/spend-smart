-- Step 1: Disable RLS temporarily to confirm data flows
-- Run ALL of this in Supabase SQL Editor

-- Drop ALL existing policies
DROP POLICY IF EXISTS "groups_select" ON groups;
DROP POLICY IF EXISTS "groups_insert" ON groups;
DROP POLICY IF EXISTS "groups_update" ON groups;
DROP POLICY IF EXISTS "groups_delete" ON groups;
DROP POLICY IF EXISTS "group_members_select" ON group_members;
DROP POLICY IF EXISTS "group_members_insert" ON group_members;
DROP POLICY IF EXISTS "group_members_update" ON group_members;
DROP POLICY IF EXISTS "group_members_delete" ON group_members;
DROP POLICY IF EXISTS "group_expenses_select" ON group_expenses;
DROP POLICY IF EXISTS "group_expenses_insert" ON group_expenses;
DROP POLICY IF EXISTS "group_expenses_update" ON group_expenses;
DROP POLICY IF EXISTS "group_expenses_delete" ON group_expenses;
DROP POLICY IF EXISTS "group_expense_splits_select" ON group_expense_splits;
DROP POLICY IF EXISTS "group_expense_splits_insert" ON group_expense_splits;
DROP POLICY IF EXISTS "group_expense_splits_update" ON group_expense_splits;
DROP POLICY IF EXISTS "group_expense_items_select" ON group_expense_items;
DROP POLICY IF EXISTS "group_expense_items_insert" ON group_expense_items;
DROP POLICY IF EXISTS "group_expense_items_update" ON group_expense_items;
DROP POLICY IF EXISTS "group_expense_items_delete" ON group_expense_items;

-- Also drop any old-named policies that might remain
DROP POLICY IF EXISTS "Authenticated users can create groups" ON groups;
DROP POLICY IF EXISTS "Anyone can look up groups by invite code" ON groups;
DROP POLICY IF EXISTS "Users can update groups they belong to" ON groups;
DROP POLICY IF EXISTS "Users can delete groups they belong to" ON groups;
DROP POLICY IF EXISTS "Group creators can update their groups" ON groups;
DROP POLICY IF EXISTS "Group creators can delete their groups" ON groups;
DROP POLICY IF EXISTS "Users can view members of their groups" ON group_members;
DROP POLICY IF EXISTS "Users can add members to their groups" ON group_members;

-- Disable RLS on all group tables
ALTER TABLE groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_expense_splits DISABLE ROW LEVEL SECURITY;
ALTER TABLE group_expense_items DISABLE ROW LEVEL SECURITY;