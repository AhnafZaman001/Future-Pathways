-- =========================================================
-- restore_auth_policies.sql
--
-- Run this ONCE in Supabase Dashboard → SQL Editor.
--
-- Undoes remove_auth_open_access.sql (if you ran it) now that
-- real Supabase Auth login is back (mirroring AXIOM: email +
-- password, no self-signup — create each student's account
-- yourself in Authentication -> Add user). Restores the
-- original auth.uid()-scoped policies and foreign keys from
-- future_pathways_schema.sql, so each student can only read
-- and write their own row again.
-- =========================================================

-- ---------------------------------------------------------
-- students — re-link id to app_users(id) (which is 1:1 with
-- auth.users via the on_auth_user_created trigger).
-- ---------------------------------------------------------
alter table public.students
  drop constraint if exists students_id_fkey;
alter table public.students
  add constraint students_id_fkey foreign key (id)
  references public.app_users(id) on delete cascade;

drop policy if exists "Open access to student profiles" on public.students;
drop policy if exists "Student manages own profile" on public.students;
create policy "Student manages own profile"
  on public.students for all
  to authenticated
  using (id = auth.uid() or public.current_role() in ('counsellor','admin'))
  with check (id = auth.uid());

revoke all on public.students from anon;
grant select, insert, update on public.students to authenticated;

-- ---------------------------------------------------------
-- future_pathways
-- ---------------------------------------------------------
alter table public.future_pathways
  drop constraint if exists future_pathways_student_id_fkey;
alter table public.future_pathways
  add constraint future_pathways_student_id_fkey foreign key (student_id)
  references public.students(id) on delete cascade;

drop policy if exists "Open select on future_pathways" on public.future_pathways;
drop policy if exists "Open insert of drafts on future_pathways" on public.future_pathways;
drop policy if exists "Open update of drafts on future_pathways" on public.future_pathways;
drop policy if exists "Student selects own or staff selects all" on public.future_pathways;
drop policy if exists "Student inserts own draft" on public.future_pathways;
drop policy if exists "Student updates own draft only" on public.future_pathways;

create policy "Student selects own or staff selects all"
  on public.future_pathways for select
  to authenticated
  using (student_id = auth.uid() or public.current_role() in ('counsellor','admin'));

create policy "Student inserts own draft"
  on public.future_pathways for insert
  to authenticated
  with check (student_id = auth.uid() and status = 'draft');

create policy "Student updates own draft only"
  on public.future_pathways for update
  to authenticated
  using (student_id = auth.uid() and status = 'draft')
  with check (student_id = auth.uid());

revoke all on public.future_pathways from anon;
grant select, insert, update on public.future_pathways to authenticated;

-- ---------------------------------------------------------
-- Ranked preferences (institutes / faculties / programs)
-- ---------------------------------------------------------
drop policy if exists "Open access to institute prefs" on public.student_institute_preferences;
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
            and fp.student_id = auth.uid()
            and fp.status = 'draft')
  );

drop policy if exists "Open access to faculty prefs" on public.student_faculty_preferences;
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
            and fp.student_id = auth.uid()
            and fp.status = 'draft')
  );

drop policy if exists "Open access to program prefs" on public.student_program_preferences;
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
            and fp.student_id = auth.uid()
            and fp.status = 'draft')
  );

revoke all on public.student_institute_preferences from anon;
revoke all on public.student_faculty_preferences from anon;
revoke all on public.student_program_preferences from anon;
grant select, insert, update, delete on public.student_institute_preferences to authenticated;
grant select, insert, update, delete on public.student_faculty_preferences to authenticated;
grant select, insert, update, delete on public.student_program_preferences to authenticated;

-- ---------------------------------------------------------
-- office_evaluations — counsellor/admin only again; students
-- get read-only visibility into their own once one exists.
-- ---------------------------------------------------------
drop policy if exists "Open access to evaluations" on public.office_evaluations;
drop policy if exists "Staff manage evaluations" on public.office_evaluations;
create policy "Staff manage evaluations"
  on public.office_evaluations for all
  to authenticated
  using (public.current_role() in ('counsellor','admin'))
  with check (public.current_role() in ('counsellor','admin'));

drop policy if exists "Student reads own evaluation" on public.office_evaluations;
create policy "Student reads own evaluation"
  on public.office_evaluations for select
  to authenticated
  using (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id and fp.student_id = auth.uid())
  );

revoke all on public.office_evaluations from anon;
grant select, insert, update on public.office_evaluations to authenticated;

-- ---------------------------------------------------------
-- Reminder: creating accounts.
-- There is no signup page. To let a student sign in, go to
-- Supabase Dashboard -> Authentication -> Users -> Add user,
-- set their email + a password, and hand it to them. The
-- on_auth_user_created trigger (see future_pathways_schema.sql)
-- automatically creates their public.app_users row with role
-- 'student'. To make someone a counsellor/admin, update their
-- role afterwards: update public.app_users set role = 'admin'
-- where id = '<their auth user id>';
-- ---------------------------------------------------------
