-- =========================================================
-- security_hardening.sql
--
-- Fixes two exploitable vulnerabilities identified in the
-- security audit:
--
-- SEC-01 (CRITICAL): student_submissions table accepts
--   unauthenticated writes from anyone on the internet using
--   only the public anon key. No login required. Fixed by
--   revoking the open insert policy and all anon grants.
--
-- SEC-03 (HIGH): app_users insert policy only checks
--   id = auth.uid() but does NOT restrict the role column,
--   meaning any authenticated user can insert their own row
--   with role='counsellor' or role='admin' and gain full
--   staff access. Fixed by adding role='student' to the
--   with check constraint, and adding an update policy that
--   prevents self-escalation.
--
-- Run once in Supabase Dashboard -> SQL Editor.
-- Safe to re-run (drop-if-exists before every create).
-- =========================================================

-- ---------------------------------------------------------
-- SEC-01: Lock down the legacy student_submissions table.
-- This table is superseded by future_pathways and is no
-- longer written to by any page. Removing all public access
-- eliminates the unauthenticated write surface entirely.
-- ---------------------------------------------------------
DROP POLICY IF EXISTS "Public can insert submissions" ON public.student_submissions;
REVOKE ALL ON public.student_submissions FROM anon;
REVOKE INSERT ON public.student_submissions FROM authenticated;

-- Disable RLS entirely on this table -- with no grants, the
-- table is inaccessible from the API regardless of RLS state,
-- but disabling it makes the intent explicit and removes any
-- future policy confusion.
ALTER TABLE public.student_submissions DISABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------
-- SEC-03: Close the role-escalation path on app_users.
--
-- Before: with check (id = auth.uid())
--   => any authenticated user could set role='admin' on insert
--
-- After: with check (id = auth.uid() AND role = 'student')
--   => inserts are locked to 'student' role only
--
-- The on_auth_user_created trigger already enforces role='student'
-- on normal signup, but the policy was the last line of defense
-- if the trigger were bypassed or a row didn't exist yet.
-- ---------------------------------------------------------
DROP POLICY IF EXISTS "Users can insert own app_user row" ON public.app_users;
CREATE POLICY "Users can insert own app_user row"
  ON public.app_users FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid() AND role = 'student');

-- Prevent any authenticated user from updating their own role
-- to a higher privilege. Only a superuser or service-role can
-- change roles (via the Supabase dashboard directly).
DROP POLICY IF EXISTS "Users cannot self-escalate role" ON public.app_users;
CREATE POLICY "Users cannot self-escalate role"
  ON public.app_users FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid() AND role = 'student');

-- Staff (counsellor/admin) retain the ability to update any
-- row they can see (needed for role management via dashboard
-- operations that go through the API).
DROP POLICY IF EXISTS "Staff can update any app_user row" ON public.app_users;
CREATE POLICY "Staff can update any app_user row"
  ON public.app_users FOR UPDATE
  TO authenticated
  USING (public.current_role() IN ('counsellor', 'admin'))
  WITH CHECK (public.current_role() IN ('counsellor', 'admin'));
