-- =========================================================
-- counsellor_remove_own_student_profile.sql
--
-- Real scenario this fixes: a counsellor/admin account was
-- earlier used/tested as a student (or a student account was
-- later promoted to counsellor/admin), leaving a `students` row
-- + possibly a `future_pathways` submission tied to the SAME
-- auth.uid() as their real counsellor login. counsellor_delete_
-- student() deliberately REFUSES to target auth.uid() (see its
-- own comment -- that guard exists specifically so a counsellor
-- can't accidentally delete their own login while cleaning up
-- other students), which is correct behaviour but leaves no way
-- to do the narrower, actually-wanted thing: strip just the
-- leftover STUDENT-side data, while keeping the app_users row
-- and the underlying auth.users login intact.
--
-- This function does exactly that, for the CALLER's own account
-- only -- there's no student_id parameter, it always operates on
-- auth.uid(), so there's no way to point it at anyone else.
--
-- students -> future_pathways -> preference tables + office_
-- evaluations all cascade via "on delete cascade" FKs already in
-- future_pathways_schema.sql, so deleting the students row alone
-- is sufficient -- no manual per-table cleanup needed here, unlike
-- counsellor_delete_student() (which also has to reach into
-- app_users/auth.users, tables that do NOT cascade from students
-- and are deliberately left untouched by this function).
--
-- Run once in the SQL Editor. Safe to re-run (create-or-replace).
-- =========================================================

create or replace function public.counsellor_remove_own_student_profile()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if public.current_role() not in ('counsellor','admin') then
    raise exception 'Only counsellors/admins can use this.';
  end if;

  -- Cascades to future_pathways -> preference tables + office_evaluations.
  -- Deliberately does NOT touch app_users or auth.users -- this
  -- account's actual counsellor/admin login is untouched.
  delete from public.students where id = uid;
end;
$$;

grant execute on function public.counsellor_remove_own_student_profile() to authenticated;
