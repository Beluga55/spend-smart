-- ============================================================
-- Fix: ensure Realtime events are delivered to all group members.
--
-- Two root causes addressed:
--
--  1. is_group_member() was marked STABLE.  PostgreSQL may cache STABLE
--     function results within a query/transaction, which can cause
--     auth.uid() to return a stale value in the Realtime evaluation
--     context.  Changing to VOLATILE forces a fresh evaluation every
--     time, guaranteeing correct membership checks.
--
--  2. groups_select still required is_group_member(), blocking the
--     invite-code / QR join flow for new users (migration 00003 fixed
--     this at the app level but may not have been applied in DB yet).
--     We open groups_select to all authenticated users for active groups.
--
--  3. Ensure the five group tables are part of the Realtime publication
--     so Supabase can broadcast change events to connected clients.
--
-- Run this entire script in your Supabase SQL Editor.
-- ============================================================

-- ── 1. Recreate is_group_member as VOLATILE ──────────────────
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
VOLATILE                -- was STABLE; VOLATILE prevents auth.uid() caching
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_members
    WHERE group_id  = p_group_id
      AND user_id   = auth.uid()
      AND is_active = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_group_member(UUID) TO authenticated;

-- ── 2. Open groups_select to all authenticated users ─────────
-- The invite code is the secret, not the group record itself.
-- A new joiner must be able to look up the group before they can
-- be inserted into group_members.
DROP POLICY IF EXISTS "groups_select" ON groups;
CREATE POLICY "groups_select" ON groups
  FOR SELECT TO authenticated
  USING (is_active = true);

-- ── 3. Ensure tables are in the Realtime publication ─────────
-- These ALTER statements are idempotent on Supabase (re-adding a table
-- that's already in the publication is a no-op in recent PG versions).
-- If you get a "relation already exists in publication" error, ignore it.
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.group_expenses;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.group_expense_splits;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.group_expense_items;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.group_members;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.groups;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;
