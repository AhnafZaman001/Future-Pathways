-- =========================================================
-- verify_migrations.sql
--
-- Run this in Supabase Dashboard -> SQL Editor to check which
-- of the one-time migration/hardening scripts in this folder
-- have actually been applied to THIS database. Every other .sql
-- file here is meant to be pasted in and run by hand -- there's
-- no migration tracker, so this is the only way to know what's
-- actually live versus what's just sitting in the repo.
--
-- Read the output of each block. Safe to run repeatedly --
-- read-only, changes nothing.
-- =========================================================

-- ---------------------------------------------------------
-- 1. security_hardening.sql applied?
--    Expect: student_submissions has RLS disabled, zero grants
--    to anon, zero INSERT grant to authenticated.
-- ---------------------------------------------------------
select
  'security_hardening.sql (SEC-01)' as check_name,
  case
    when relrowsecurity = false then 'APPLIED (RLS disabled as expected)'
    else 'NOT APPLIED -- RLS is still ON, table may still be writable'
  end as status
from pg_class
where relname = 'student_submissions' and relnamespace = 'public'::regnamespace;

select
  'security_hardening.sql (SEC-01 grants)' as check_name,
  case
    when count(*) = 0 then 'APPLIED (no anon/authenticated grants remain)'
    else 'NOT APPLIED -- grants still present: ' || string_agg(grantee || '/' || privilege_type, ', ')
  end as status
from information_schema.role_table_grants
where table_schema = 'public' and table_name = 'student_submissions'
  and grantee in ('anon', 'authenticated');

-- Expect: app_users insert policy's WITH CHECK includes role = 'student'
select
  'security_hardening.sql (SEC-03)' as check_name,
  case
    when count(*) > 0 then 'APPLIED (role-locked insert policy found)'
    else 'NOT APPLIED -- no role-locked insert policy on app_users'
  end as status
from pg_policies
where schemaname = 'public' and tablename = 'app_users'
  and cmd = 'INSERT' and with_check ilike '%role%student%';

-- ---------------------------------------------------------
-- 2. counsellor_managed_students.sql applied?
--    Expect: counsellor_create_student() function exists.
-- ---------------------------------------------------------
select
  'counsellor_managed_students.sql' as check_name,
  case
    when count(*) > 0 then 'APPLIED (counsellor_create_student() exists)'
    else 'NOT APPLIED -- function missing'
  end as status
from pg_proc
where proname = 'counsellor_create_student' and pronamespace = 'public'::regnamespace;

-- ---------------------------------------------------------
-- 3. counsellor_delete_student.sql applied?
-- ---------------------------------------------------------
select
  'counsellor_delete_student.sql' as check_name,
  case
    when count(*) > 0 then 'APPLIED (counsellor_delete_student() exists)'
    else 'NOT APPLIED -- function missing'
  end as status
from pg_proc
where proname = 'counsellor_delete_student' and pronamespace = 'public'::regnamespace;

-- ---------------------------------------------------------
-- 4. Which auth policy set is currently live on `students`?
--    restore_auth_policies.sql tightens WITH CHECK back to
--    id = auth.uid() only; counsellor_managed_students.sql
--    loosens it to also allow staff. These two files directly
--    conflict if run out of order -- this tells you which one
--    "won".
-- ---------------------------------------------------------
select
  'students table -- current INSERT/UPDATE policy' as check_name,
  policyname,
  with_check
from pg_policies
where schemaname = 'public' and tablename = 'students' and cmd = 'ALL';

-- ---------------------------------------------------------
-- 5. Blanket RLS sweep -- every public table and whether RLS
--    is actually turned on. Anything showing "false" here
--    (other than student_submissions, which is intentional)
--    is a real gap worth checking by hand.
-- ---------------------------------------------------------
select
  relname as table_name,
  relrowsecurity as rls_enabled
from pg_class
where relnamespace = 'public'::regnamespace
  and relkind = 'r'
order by relrowsecurity asc, relname;
