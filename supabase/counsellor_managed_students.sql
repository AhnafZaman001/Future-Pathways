-- =========================================================
-- Counsellor-managed students
--
-- Real workflow this supports: a counsellor sits at a desk,
-- brings students up in batches, and enters each student's
-- info + preferences directly, on the student's behalf, in one
-- sitting. The student never logs in themselves.
--
-- Two bugs this fixes:
--
-- 1. RLS write policies were read-permissive but write-blind for
--    staff. `using (id = auth.uid() or is staff)` already let a
--    counsellor SEE every student (that's why admin.html could
--    already list everyone) -- but `with check (id = auth.uid())`
--    on the same policies meant a counsellor could never actually
--    WRITE on behalf of anyone but themselves. That's the root
--    cause of "I can't edit any student's form."
--
-- 2. pathways.html had no concept of "editing someone else's
--    form" at all -- it was hard-wired to auth.uid() as the one
--    student it could ever represent. Fixed in js/fp-app.js
--    (?student=<id> query param, staff-only) alongside this file.
--
-- Run once in the SQL Editor. Safe to re-run (drop-and-recreate
-- policies, create-or-replace functions).
-- =========================================================

-- ---------------------------------------------------------
-- 1. Loosen write policies: staff can write on behalf of ANY
--    student, regardless of the submission's current status
--    (needed to edit an already-submitted form, or reset one).
-- ---------------------------------------------------------

drop policy if exists "Student manages own profile" on public.students;
create policy "Student manages own profile"
  on public.students for all
  to authenticated
  using (id = auth.uid() or public.current_role() in ('counsellor','admin'))
  with check (id = auth.uid() or public.current_role() in ('counsellor','admin'));

drop policy if exists "future_pathways insert" on public.future_pathways;
create policy "future_pathways insert"
  on public.future_pathways for insert
  to authenticated
  with check (
    (student_id = auth.uid() and status = 'draft')
    or public.current_role() in ('counsellor','admin')
  );

drop policy if exists "future_pathways update" on public.future_pathways;
create policy "future_pathways update"
  on public.future_pathways for update
  to authenticated
  using (
    (student_id = auth.uid() and status = 'draft')
    or public.current_role() in ('counsellor','admin')
  )
  with check (
    student_id = auth.uid()
    or public.current_role() in ('counsellor','admin')
  );

drop policy if exists "Owner manages institute prefs" on public.student_institute_preferences;
create policy "Owner manages institute prefs"
  on public.student_institute_preferences for all
  to authenticated
  using (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and (fp.student_id = auth.uid() or public.current_role() in ('counsellor','admin')))
  )
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and ((fp.student_id = auth.uid() and fp.status = 'draft')
                 or public.current_role() in ('counsellor','admin')))
  );

drop policy if exists "Owner manages faculty prefs" on public.student_faculty_preferences;
create policy "Owner manages faculty prefs"
  on public.student_faculty_preferences for all
  to authenticated
  using (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and (fp.student_id = auth.uid() or public.current_role() in ('counsellor','admin')))
  )
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and ((fp.student_id = auth.uid() and fp.status = 'draft')
                 or public.current_role() in ('counsellor','admin')))
  );

drop policy if exists "Owner manages program prefs" on public.student_program_preferences;
create policy "Owner manages program prefs"
  on public.student_program_preferences for all
  to authenticated
  using (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and (fp.student_id = auth.uid() or public.current_role() in ('counsellor','admin')))
  )
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and ((fp.student_id = auth.uid() and fp.status = 'draft')
                 or public.current_role() in ('counsellor','admin')))
  );

-- ---------------------------------------------------------
-- 2. counsellor_create_student() -- creates a new, non-login-
--    capable student account and returns its id. The client then
--    treats that id exactly like any other student_id
--    (pathways.html?student=<id>) -- the existing form code
--    already lazily creates the students/future_pathways rows on
--    first save (ensureFuturePathwayRow() / saveProfile() in
--    js/fp-app.js), so this function doesn't need to pre-create
--    them, only the backing account those inserts require.
--
--    Same non-login-capable account shape as
--    load_test_seed_100_students.sql (no auth.identities row, no
--    real password hash) -- there, that was deliberate because a
--    load test doesn't need login either; here, it's deliberate
--    because the confirmed real workflow is "student never logs
--    in, counsellor manages everything."
-- ---------------------------------------------------------
create or replace function public.counsellor_create_student()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
begin
  if public.current_role() not in ('counsellor','admin') then
    raise exception 'Only counsellors/admins can add a student.';
  end if;

  new_id := gen_random_uuid();

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', new_id, 'authenticated', 'authenticated',
    'student-' || replace(new_id::text, '-', '') || '@no-login.kips.internal',
    'not-a-real-password-hash-counsellor-managed', now(),
    '{"provider":"counsellor_managed","providers":["counsellor_managed"]}'::jsonb, '{}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  );
  -- on_auth_user_created trigger fires here and creates the
  -- matching public.app_users row (role defaults to 'student').

  return new_id;
end;
$$;

grant execute on function public.counsellor_create_student() to authenticated;

-- ---------------------------------------------------------
-- 3. counsellor_reset_submission() -- "delete a student's form",
--    per the confirmed meaning: reset to an editable draft, KEEP
--    the account (students row -- name, roll number, marks --
--    untouched), CLEAR the answers (all ranked preferences +
--    additional_information), submitted_at cleared, status back
--    to 'draft'.
-- ---------------------------------------------------------
create or replace function public.counsellor_reset_submission(p_future_pathway_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.current_role() not in ('counsellor','admin') then
    raise exception 'Only counsellors/admins can reset a submission.';
  end if;

  delete from public.student_institute_preferences where future_pathway_id = p_future_pathway_id;
  delete from public.student_faculty_preferences where future_pathway_id = p_future_pathway_id;
  delete from public.student_program_preferences where future_pathway_id = p_future_pathway_id;

  update public.future_pathways
  set status = 'draft', submitted_at = null, additional_information = null
  where id = p_future_pathway_id;
end;
$$;

grant execute on function public.counsellor_reset_submission(uuid) to authenticated;
