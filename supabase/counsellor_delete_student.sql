-- =========================================================
-- counsellor_delete_student() -- a REAL, PERMANENT delete.
--
-- Direct feedback on the existing "Delete" button in admin.html:
-- it only ever did what counsellor_reset_submission() does --
-- clear the submitted answers, keep the account (students row --
-- name, roll number, marks) intact. That's a real gap: there was
-- no way to actually remove a student's name from the database at
-- all. Two separate, clearly distinct actions now exist:
--
--   - counsellor_reset_submission() (unchanged, see
--     counsellor_managed_students.sql) -- "Clear student's data":
--     reversible-ish, keeps the account, clears the answers.
--   - counsellor_delete_student() (this file) -- "Delete":
--     irreversible, removes the account (students row, app_users
--     row, and the underlying auth.users row) entirely, along
--     with every future_pathways row and preference row tied to
--     it. There is no undo. The frontend confirm-dialog wording
--     for this action is deliberately much more severe than for
--     "Clear student's data" -- see js/fp-admin.js.
--
-- Deletes, in FK-safe order: preference rows for every
-- future_pathways row this student has -> the future_pathways
-- row(s) themselves -> the students row -> the app_users row ->
-- the underlying auth.users row. SECURITY DEFINER, same pattern
-- already proven in counsellor_create_student() (which INSERTs
-- into auth.users the same way this DELETEs from it) -- the
-- function runs with the definer's privileges, not the calling
-- counsellor's, which is what makes touching auth.users possible
-- at all from client-side code.
--
-- Run once in the SQL Editor. Safe to re-run
-- (create-or-replace).
-- =========================================================

create or replace function public.counsellor_delete_student(p_student_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  fp_id uuid;
begin
  if public.current_role() not in ('counsellor','admin') then
    raise exception 'Only counsellors/admins can delete a student.';
  end if;

  -- Defensive guard: a counsellor/admin should never be able to
  -- delete their own account through this path (it's meant for
  -- deleting the students they manage, not themselves) -- cheap
  -- insurance against a stray or malformed call given this is
  -- irreversible.
  if p_student_id = auth.uid() then
    raise exception 'Cannot delete your own account through this function.';
  end if;

  for fp_id in select id from public.future_pathways where student_id = p_student_id loop
    delete from public.student_institute_preferences where future_pathway_id = fp_id;
    delete from public.student_faculty_preferences where future_pathway_id = fp_id;
    delete from public.student_program_preferences where future_pathway_id = fp_id;
  end loop;

  delete from public.future_pathways where student_id = p_student_id;
  delete from public.students where id = p_student_id;
  delete from public.app_users where id = p_student_id;
  delete from auth.users where id = p_student_id;
end;
$$;

grant execute on function public.counsellor_delete_student(uuid) to authenticated;
