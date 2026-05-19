-- ============================================================
-- Re-enable RLS on all group tables using a SECURITY DEFINER
-- helper function to avoid infinite recursion in group_members
-- policies.
--
-- Run this entire script in your Supabase SQL Editor.
-- ============================================================

-- ── 0. Drop ALL existing policies (clean slate) ─────────────
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN (
        'groups', 'group_members', 'group_expenses',
        'group_expense_splits', 'group_expense_items'
      )
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      r.policyname, r.schemaname, r.tablename
    );
  END LOOP;
END $$;

-- ── 1. SECURITY DEFINER helper (bypasses RLS so no recursion) ─
-- Returns true if the calling user is an active member of p_group_id.
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id   = auth.uid()
      AND is_active = true
  );
$$;

-- ── 2. Re-enable RLS ────────────────────────────────────────
ALTER TABLE groups                ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members         ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_expenses        ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_expense_splits  ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_expense_items   ENABLE ROW LEVEL SECURITY;

-- ── 3. groups ───────────────────────────────────────────────
-- Anyone authenticated can look up an active group (needed for invite-code join flow).
CREATE POLICY "groups_select" ON groups
  FOR SELECT TO authenticated
  USING (is_active = true AND (created_by = auth.uid() OR public.is_group_member(id)));

CREATE POLICY "groups_insert" ON groups
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "groups_update" ON groups
  FOR UPDATE TO authenticated
  USING (created_by = auth.uid() OR public.is_group_member(id));

CREATE POLICY "groups_delete" ON groups
  FOR DELETE TO authenticated
  USING (created_by = auth.uid() OR public.is_group_member(id));

-- ── 4. group_members ────────────────────────────────────────
-- SELECT: own row OR member of that group (no self-reference — uses helper).
CREATE POLICY "group_members_select" ON group_members
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_group_member(group_id));

-- INSERT: user can only insert themselves into an active group.
CREATE POLICY "group_members_insert" ON group_members
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM groups
      WHERE id = group_id AND is_active = true
    )
  );

-- UPDATE: own record, or a group admin.
CREATE POLICY "group_members_update" ON group_members
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid() OR public.is_group_member(group_id));

-- DELETE: own record, or group creator.
CREATE POLICY "group_members_delete" ON group_members
  FOR DELETE TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM groups
      WHERE id = group_id AND created_by = auth.uid()
    )
  );

-- ── 5. group_expenses ───────────────────────────────────────
CREATE POLICY "group_expenses_select" ON group_expenses
  FOR SELECT TO authenticated
  USING (public.is_group_member(group_id));

CREATE POLICY "group_expenses_insert" ON group_expenses
  FOR INSERT TO authenticated
  WITH CHECK (public.is_group_member(group_id));

CREATE POLICY "group_expenses_update" ON group_expenses
  FOR UPDATE TO authenticated
  USING (public.is_group_member(group_id));

CREATE POLICY "group_expenses_delete" ON group_expenses
  FOR DELETE TO authenticated
  USING (public.is_group_member(group_id));


-- ── 6. group_expense_splits ─────────────────────────────────
CREATE POLICY "group_expense_splits_select" ON group_expense_splits
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM group_expenses ge
      WHERE ge.id = group_expense_id
        AND public.is_group_member(ge.group_id)
    )
  );

CREATE POLICY "group_expense_splits_insert" ON group_expense_splits
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_expenses ge
      WHERE ge.id = group_expense_id
        AND public.is_group_member(ge.group_id)
    )
  );

CREATE POLICY "group_expense_splits_update" ON group_expense_splits
  FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM group_expenses ge
      WHERE ge.id = group_expense_id
        AND public.is_group_member(ge.group_id)
    )
  );

CREATE POLICY "group_expense_splits_delete" ON group_expense_splits
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_expenses ge
      WHERE ge.id = group_expense_id
        AND public.is_group_member(ge.group_id)
    )
  );

-- ── 7. group_expense_items ──────────────────────────────────
CREATE POLICY "group_expense_items_select" ON group_expense_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_expenses ge
      WHERE ge.id = group_expense_id
        AND public.is_group_member(ge.group_id)
    )
  );

CREATE POLICY "group_expense_items_insert" ON group_expense_items
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM group_expenses ge
      WHERE ge.id = group_expense_id
        AND public.is_group_member(ge.group_id)
    )
  );

CREATE POLICY "group_expense_items_update" ON group_expense_items
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_expenses ge
      WHERE ge.id = group_expense_id
        AND public.is_group_member(ge.group_id)
    )
  );

CREATE POLICY "group_expense_items_delete" ON group_expense_items
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM group_expenses ge
      WHERE ge.id = group_expense_id
        AND public.is_group_member(ge.group_id)
    )
  );

-- ── 8. Grant execute on the helper ─────────────────────────
GRANT EXECUTE ON FUNCTION public.is_group_member(UUID) TO authenticated;
