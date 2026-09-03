-- =========================================================
-- migration_multi_institution.sql
--
-- Retrofits Future Pathways for two institutions sharing one
-- deployment (KIPS College, already live, + KIPS Academy, new) --
-- same URL, same codebase, no separate repo/database, but with
-- STRICT data isolation: a counsellor/admin at one institution can
-- never see, edit, or delete the other institution's students,
-- submissions, preferences, or evaluations. No cross-institution
-- account exists by design.
--
-- IMPORTANT: this migration is written against the CURRENT live
-- policy state, confirmed directly rather than assumed --
-- counsellors can currently edit/submit a student's form on their
-- behalf, even after submission (the permissive shape from
-- counsellor_managed_students.sql, not the more restrictive
-- draft-only shape in future_pathways_schema.sql /
-- restore_auth_policies.sql). Every policy below preserves that
-- exact permissiveness and only adds institution scoping on top of
-- it -- this is not a capability regression.
--
-- Also fixes three SECURITY DEFINER functions
-- (counsellor_delete_student, counsellor_create_student,
-- counsellor_reset_submission) that had NO institution check at
-- all -- being SECURITY DEFINER, they bypass RLS entirely, so
-- fixing the policies above does not protect them. Before this
-- fix, a counsellor at one institution could call
-- counsellor_delete_student() or counsellor_reset_submission() with
-- another institution's future_pathway_id/student_id and it would
-- succeed silently.
--
-- The shared university/faculty/program/career catalog (institutes,
-- fp_faculties, program_options, career_options, merit formulas)
-- is left completely untouched -- confirmed shared between both
-- institutions.
--
-- Run this once, in order, against the SAME live Supabase project
-- Future Pathways already uses -- this is an additive retrofit, not
-- a new database.
-- =========================================================

-- ---------------------------------------------------------
-- 1. institutions table
-- ---------------------------------------------------------
create table if not exists public.institutions (
  id    uuid primary key default gen_random_uuid(),
  name  text not null,
  slug  text not null unique
);

insert into public.institutions (name, slug) values
  ('KIPS College', 'kips-college'),
  ('KIPS Academy', 'kips-academy')
on conflict (slug) do nothing;

grant select on public.institutions to authenticated, anon;

-- ---------------------------------------------------------
-- 2. Add institution_id to every tenant-scoped table. Nullable --
-- a NULL institution_id is safe by construction: every policy
-- below compares it to a specific id, and NULL never equals
-- anything in SQL, so an unset row is invisible to everyone rather
-- than accidentally exposed.
-- ---------------------------------------------------------
alter table public.app_users       add column if not exists institution_id uuid references public.institutions(id);
alter table public.students        add column if not exists institution_id uuid references public.institutions(id);
alter table public.future_pathways add column if not exists institution_id uuid references public.institutions(id);

-- ---------------------------------------------------------
-- 3. Backfill: every row that already exists belongs to the
-- original, already-live deployment -- KIPS College.
-- ---------------------------------------------------------
update public.app_users       set institution_id = (select id from public.institutions where slug = 'kips-college') where institution_id is null;
update public.students        set institution_id = (select id from public.institutions where slug = 'kips-college') where institution_id is null;
update public.future_pathways set institution_id = (select id from public.institutions where slug = 'kips-college') where institution_id is null;

-- ---------------------------------------------------------
-- 4. handle_new_user() -- now also assigns institution_id from an
-- `institution_slug` key in the new user's metadata, if present.
--
-- Two paths create a new auth user, and both now supply this:
--   a) Admin manually adding a user via Supabase Dashboard -> the
--      "Add user" form has a raw user metadata field; set
--      {"institution_slug": "kips-academy"} there. If omitted,
--      institution_id stays NULL and must be set manually after
--      (same two-step process as setting `role` already was):
--        update public.app_users set institution_id = (select id from public.institutions where slug = 'kips-academy')
--        where id = 'PASTE-USER-UID-HERE';
--   b) counsellor_create_student() (fixed in step 7 below) -- now
--      passes the CALLING counsellor's own institution_slug
--      automatically, so a student created by a KIPS Academy
--      counsellor is correctly a KIPS Academy student with no
--      manual follow-up needed.
-- ---------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta_institution_slug text := new.raw_user_meta_data->>'institution_slug';
  resolved_institution_id uuid;
begin
  if meta_institution_slug is not null then
    select id into resolved_institution_id from public.institutions where slug = meta_institution_slug;
  end if;
  insert into public.app_users (id, full_name, institution_id)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.email), resolved_institution_id);
  return new;
end;
$$;

-- ---------------------------------------------------------
-- 5. Security-definer helper -- same safe pattern this schema
-- already uses correctly for current_role(). Returns the calling
-- user's own institution_id without re-triggering RLS on app_users.
-- ---------------------------------------------------------
create or replace function public.current_institution_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select institution_id from public.app_users where id = auth.uid();
$$;

-- Attach it as the default for students/future_pathways -- ordinary
-- app inserts (a student saving their own profile, a student or
-- counsellor creating a future_pathways draft) automatically get
-- the correct institution_id with ZERO application code changes,
-- since whoever is actually performing the insert already has
-- their own institution_id resolved by this point. Not applied to
-- app_users, whose own row is created by the trigger above at the
-- exact moment that row doesn't exist yet -- current_institution_id()
-- would circularly resolve to NULL there.
alter table public.students        alter column institution_id set default public.current_institution_id();
alter table public.future_pathways alter column institution_id set default public.current_institution_id();

-- ---------------------------------------------------------
-- 6. RLS policies. Every "drop policy if exists" below lists every
-- historical name this policy has had across future_pathways_
-- schema.sql, restore_auth_policies.sql, and counsellor_managed_
-- students.sql -- cleans up any duplicate/overlapping policy left
-- over regardless of which combination of those files was actually
-- run previously, so this migration ends with exactly ONE policy
-- per table/action either way.
-- ---------------------------------------------------------

-- app_users (read policy only -- insert/update policies are
-- untouched, they already came from security_hardening.sql and
-- don't need institution scoping: insert is locked to
-- role='student' for the caller's own row regardless of
-- institution, and the anti-self-escalation update policy is also
-- own-row-only)
drop policy if exists "Users can view own app_user row" on public.app_users;
create policy "Users can view own app_user row"
  on public.app_users for select
  to authenticated
  using (
    id = auth.uid()
    or (public.current_role() in ('counsellor','admin') and institution_id = public.current_institution_id())
  );

-- students -- staff can write on behalf of ANY student (confirmed
-- current behavior), now scoped to their own institution only.
drop policy if exists "Student manages own profile" on public.students;
drop policy if exists "Open access to student profiles" on public.students;
create policy "Student manages own profile"
  on public.students for all
  to authenticated
  using (
    id = auth.uid()
    or (public.current_role() in ('counsellor','admin') and institution_id = public.current_institution_id())
  )
  with check (
    id = auth.uid()
    or (public.current_role() in ('counsellor','admin') and institution_id = public.current_institution_id())
  );

-- future_pathways -- select
drop policy if exists "Student selects own or staff selects all" on public.future_pathways;
drop policy if exists "Open select on future_pathways" on public.future_pathways;
create policy "Student selects own or staff selects all"
  on public.future_pathways for select
  to authenticated
  using (
    student_id = auth.uid()
    or (public.current_role() in ('counsellor','admin') and institution_id = public.current_institution_id())
  );

-- future_pathways -- insert (staff can insert on behalf of any
-- student, any status, per confirmed current behavior)
drop policy if exists "Student inserts own draft" on public.future_pathways;
drop policy if exists "future_pathways insert" on public.future_pathways;
drop policy if exists "Open insert of drafts on future_pathways" on public.future_pathways;
create policy "future_pathways insert"
  on public.future_pathways for insert
  to authenticated
  with check (
    (student_id = auth.uid() and status = 'draft' and institution_id = public.current_institution_id())
    or (public.current_role() in ('counsellor','admin') and institution_id = public.current_institution_id())
  );

-- future_pathways -- update (staff can update on behalf of any
-- student regardless of current status, per confirmed current
-- behavior -- this is what lets a counsellor edit an
-- already-submitted form)
drop policy if exists "Student updates own draft only" on public.future_pathways;
drop policy if exists "future_pathways update" on public.future_pathways;
drop policy if exists "Open update of drafts on future_pathways" on public.future_pathways;
create policy "future_pathways update"
  on public.future_pathways for update
  to authenticated
  using (
    (student_id = auth.uid() and status = 'draft')
    or (public.current_role() in ('counsellor','admin') and institution_id = public.current_institution_id())
  )
  with check (
    student_id = auth.uid()
    or (public.current_role() in ('counsellor','admin') and institution_id = public.current_institution_id())
  );

-- Ranked preference tables -- ownership flows through
-- future_pathways, so the staff-visibility branch of each check now
-- also requires the parent future_pathways row's institution_id to
-- match. Staff branch preserves the confirmed current behavior
-- (write on behalf of any student, any status).
drop policy if exists "Owner manages institute prefs" on public.student_institute_preferences;
drop policy if exists "Open access to institute prefs" on public.student_institute_preferences;
create policy "Owner manages institute prefs"
  on public.student_institute_preferences for all
  to authenticated
  using (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and (fp.student_id = auth.uid()
                 or (public.current_role() in ('counsellor','admin') and fp.institution_id = public.current_institution_id())))
  )
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and ((fp.student_id = auth.uid() and fp.status = 'draft')
                 or (public.current_role() in ('counsellor','admin') and fp.institution_id = public.current_institution_id())))
  );

drop policy if exists "Owner manages faculty prefs" on public.student_faculty_preferences;
drop policy if exists "Open access to faculty prefs" on public.student_faculty_preferences;
create policy "Owner manages faculty prefs"
  on public.student_faculty_preferences for all
  to authenticated
  using (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and (fp.student_id = auth.uid()
                 or (public.current_role() in ('counsellor','admin') and fp.institution_id = public.current_institution_id())))
  )
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and ((fp.student_id = auth.uid() and fp.status = 'draft')
                 or (public.current_role() in ('counsellor','admin') and fp.institution_id = public.current_institution_id())))
  );

drop policy if exists "Owner manages program prefs" on public.student_program_preferences;
drop policy if exists "Open access to program prefs" on public.student_program_preferences;
create policy "Owner manages program prefs"
  on public.student_program_preferences for all
  to authenticated
  using (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and (fp.student_id = auth.uid()
                 or (public.current_role() in ('counsellor','admin') and fp.institution_id = public.current_institution_id())))
  )
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id
            and ((fp.student_id = auth.uid() and fp.status = 'draft')
                 or (public.current_role() in ('counsellor','admin') and fp.institution_id = public.current_institution_id())))
  );

-- office_evaluations -- previously ANY counsellor/admin could
-- manage ANY institution's evaluations. Now scoped through
-- future_pathways the same way the preference tables are.
drop policy if exists "Staff manage evaluations" on public.office_evaluations;
drop policy if exists "Open access to evaluations" on public.office_evaluations;
create policy "Staff manage evaluations"
  on public.office_evaluations for all
  to authenticated
  using (
    public.current_role() in ('counsellor','admin')
    and exists (select 1 from public.future_pathways fp
                where fp.id = future_pathway_id and fp.institution_id = public.current_institution_id())
  )
  with check (
    public.current_role() in ('counsellor','admin')
    and exists (select 1 from public.future_pathways fp
                where fp.id = future_pathway_id and fp.institution_id = public.current_institution_id())
  );

-- institutes / fp_faculties / program_options / career_options:
-- deliberately UNCHANGED. Confirmed shared across both institutions.

-- ---------------------------------------------------------
-- 7. Fix the three SECURITY DEFINER functions that bypass RLS
-- entirely and previously had NO institution check at all.
-- ---------------------------------------------------------

-- counsellor_delete_student() -- now verifies the target student
-- belongs to the caller's own institution before deleting anything.
-- Before this fix, ANY counsellor/admin could delete ANY student
-- at either institution.
create or replace function public.counsellor_delete_student(p_student_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  fp_id uuid;
  target_institution_id uuid;
begin
  if public.current_role() not in ('counsellor','admin') then
    raise exception 'Only counsellors/admins can delete a student.';
  end if;

  if p_student_id = auth.uid() then
    raise exception 'Cannot delete your own account through this function.';
  end if;

  select institution_id into target_institution_id from public.students where id = p_student_id;
  if target_institution_id is null or target_institution_id != public.current_institution_id() then
    raise exception 'Student not found in your institution.';
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

-- counsellor_create_student() -- now explicitly passes the calling
-- counsellor's own institution_slug as metadata on the new auth
-- user, so handle_new_user() assigns the new student to the SAME
-- institution as the counsellor creating them, with no manual
-- follow-up step needed. Before this fix, new students created this
-- way had institution_id = NULL -- invisible to everyone, including
-- the counsellor who just created them.
create or replace function public.counsellor_create_student()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  caller_institution_slug text;
begin
  if public.current_role() not in ('counsellor','admin') then
    raise exception 'Only counsellors/admins can add a student.';
  end if;

  select slug into caller_institution_slug
  from public.institutions
  where id = public.current_institution_id();

  if caller_institution_slug is null then
    raise exception 'Your account has no institution set -- cannot create a student.';
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
    '{"provider":"counsellor_managed","providers":["counsellor_managed"]}'::jsonb,
    jsonb_build_object('institution_slug', caller_institution_slug),
    now(), now(),
    '', '', '', '', '', ''
  );
  -- on_auth_user_created trigger fires here, reads institution_slug
  -- from raw_user_meta_data, and creates the matching
  -- public.app_users row with the correct institution_id already set.

  return new_id;
end;
$$;

-- counsellor_reset_submission() -- now verifies the target
-- future_pathways row belongs to the caller's own institution
-- before resetting it. Before this fix, ANY counsellor/admin could
-- wipe ANY institution's submission.
create or replace function public.counsellor_reset_submission(p_future_pathway_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_institution_id uuid;
begin
  if public.current_role() not in ('counsellor','admin') then
    raise exception 'Only counsellors/admins can reset a submission.';
  end if;

  select institution_id into target_institution_id from public.future_pathways where id = p_future_pathway_id;
  if target_institution_id is null or target_institution_id != public.current_institution_id() then
    raise exception 'Submission not found in your institution.';
  end if;

  delete from public.student_institute_preferences where future_pathway_id = p_future_pathway_id;
  delete from public.student_faculty_preferences where future_pathway_id = p_future_pathway_id;
  delete from public.student_program_preferences where future_pathway_id = p_future_pathway_id;

  update public.future_pathways
  set status = 'draft', submitted_at = null, additional_information = null
  where id = p_future_pathway_id;
end;
$$;

-- counsellor_remove_own_student_profile() -- NOT modified. It only
-- ever operates on auth.uid() (the caller's own account), with no
-- id parameter at all, so there is no cross-institution path to
-- close here.

grant execute on function public.counsellor_delete_student(uuid) to authenticated;
grant execute on function public.counsellor_create_student() to authenticated;
grant execute on function public.counsellor_reset_submission(uuid) to authenticated;
