-- Fix RLS policies for group bill-splitting
-- Run this in Supabase SQL Editor to update existing policies
-- This makes invite code lookup work (allows any authenticated user to SELECT groups)
-- and allows users to join groups via invite code (INSERT into group_members)

-- Drop old policies that block invite code lookup
DROP POLICY IF EXISTS "Users can view groups they belong to" ON groups;
DROP POLICY IF EXISTS "Users can add members to their groups" ON group_members;

-- Replace with: anyone authenticated can look up groups by invite code
CREATE POLICY "Anyone can look up groups by invite code" ON groups
  FOR SELECT TO authenticated USING (is_active = true);

-- Replace with: users can join any active group (for invite code flow)
CREATE POLICY "Users can add members to their groups" ON group_members
  FOR INSERT TO authenticated WITH CHECK (
    (user_id = auth.uid()) AND
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND is_active = true)
  );