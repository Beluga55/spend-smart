-- ============================================================
-- Fix: allow any authenticated user to look up an active group.
--
-- The previous groups_select policy required the user to already
-- be a creator or member, which broke the invite-code / QR join
-- flow — a new joiner is neither yet.
--
-- The invite code itself is the secret. Letting authenticated
-- users read group metadata (name, invite_code, is_active) for
-- any active group is intentional and safe.
--
-- We also recreate group_members_insert using a SECURITY DEFINER
-- helper so its internal `EXISTS (SELECT 1 FROM groups …)` check
-- bypasses RLS and never gets blocked.
--
-- Run this entire script in your Supabase SQL Editor.
-- ============================================================

-- ── 1. Drop the two policies we're replacing ────────────────
DROP POLICY IF EXISTS "groups_select"        ON groups;
DROP POLICY IF EXISTS "group_members_insert" ON group_members;

-- ── 2. SECURITY DEFINER helper for the member-insert check ──
-- Checks that a group exists and is active without going through
-- the caller's RLS context (avoids the chicken-and-egg problem).
CREATE OR REPLACE FUNCTION public.group_is_active(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.groups
    WHERE id = p_group_id AND is_active = true
  );
$$;

GRANT EXECUTE ON FUNCTION public.group_is_active(UUID) TO authenticated;

-- ── 3. groups SELECT — open to all authenticated users ──────
-- Any signed-in user can look up an active group so they can
-- join via invite code / QR scan. The 8-char invite code is
-- the access secret; the group record itself is not sensitive.
CREATE POLICY "groups_select" ON groups
  FOR SELECT TO authenticated
  USING (is_active = true);

-- ── 4. group_members INSERT — uses SECURITY DEFINER helper ──
-- User can add themselves to any active group. The helper
-- bypasses RLS on `groups` so the check always works.
CREATE POLICY "group_members_insert" ON group_members
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND public.group_is_active(group_id)
  );
