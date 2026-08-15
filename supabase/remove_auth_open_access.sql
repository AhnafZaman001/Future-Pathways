-- =========================================================
-- remove_auth_open_access.sql
--
-- Run this ONCE in Supabase Dashboard → SQL Editor, AFTER
-- future_pathways_schema.sql has already been applied.
--
-- Context: the app no longer has a login/signup step. Every
-- browser gets a random anonymous id (stored in localStorage,
-- see js/fp-client.js) which is used as students.id / the
-- future_pathways.student_id foreign key, instead of a Supabase
-- Auth user id. Because there is no `auth.uid()` anymore, every
-- policy that referenced it is replaced with an open policy for
-- the anon (publishable-key) role.
--
-- IMPORTANT TRADE-OFF: this removes per-user data isolation.
-- Anyone with the publishable key (i.e. anyone who loads the
-- site) can read and write ANY row in these tables, including
-- other students' submissions and the admin's evaluation notes.
-- That's an acceptable trade for a low-stakes prototype used by
-- a known/trusted group, but it is NOT appropriate once this
-- holds real student PII at any scale. If that changes, the
-- fix is to reintroduce some form of identity (even a simple
-- shared passcode gate) rather than leaving this fully open.
-- =========================================================

-- ---------------------------------------------------------
-- students — drop the FK to app_users (which was 1:1 with
-- auth.users) since ids are now client-generated, not auth ids.
-- ---------------------------------------------------------
alter table public.students
  drop constraint if exists students_id_fkey;

drop policy if exists "Student manages own profile" on public.students;
create policy "Open access to student profiles"
  on public.students for all
  to anon, authenticated
  using (true)
  with check (true);

grant select, insert, update on public.students to anon;

-- ---------------------------------------------------------
-- future_pathways
-- ---------------------------------------------------------
alter table public.future_pathways
  drop constraint if exists future_pathways_student_id_fkey;

drop policy if exists "Student selects own or staff selects all" on public.future_pathways;
drop policy if exists "Student inserts own draft" on public.future_pathways;
drop policy if exists "Student updates own draft only" on public.future_pathways;

create policy "Open select on future_pathways"
  on public.future_pathways for select
  to anon, authenticated
  using (true);

create policy "Open insert of drafts on future_pathways"
  on public.future_pathways for insert
  to anon, authenticated
  with check (status = 'draft');

create policy "Open update of drafts on future_pathways"
  on public.future_pathways for update
  to anon, authenticated
  using (status = 'draft')
  with check (true);

grant select, insert, update on public.future_pathways to anon;

-- ---------------------------------------------------------
-- Ranked preferences (institutes / faculties / programs)
-- ---------------------------------------------------------
drop policy if exists "Owner manages institute prefs" on public.student_institute_preferences;
create policy "Open access to institute prefs"
  on public.student_institute_preferences for all
  to anon, authenticated
  using (true)
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id and fp.status = 'draft')
  );

drop policy if exists "Owner manages faculty prefs" on public.student_faculty_preferences;
create policy "Open access to faculty prefs"
  on public.student_faculty_preferences for all
  to anon, authenticated
  using (true)
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id and fp.status = 'draft')
  );

drop policy if exists "Owner manages program prefs" on public.student_program_preferences;
create policy "Open access to program prefs"
  on public.student_program_preferences for all
  to anon, authenticated
  using (true)
  with check (
    exists (select 1 from public.future_pathways fp
            where fp.id = future_pathway_id and fp.status = 'draft')
  );

grant select, insert, update, delete on public.student_institute_preferences to anon;
grant select, insert, update, delete on public.student_faculty_preferences to anon;
grant select, insert, update, delete on public.student_program_preferences to anon;

-- ---------------------------------------------------------
-- office_evaluations — the admin page (admin.html) is also
-- open now (no login), so this table is opened up too.
-- ---------------------------------------------------------
drop policy if exists "Staff manage evaluations" on public.office_evaluations;
drop policy if exists "Student reads own evaluation" on public.office_evaluations;

create policy "Open access to evaluations"
  on public.office_evaluations for all
  to anon, authenticated
  using (true)
  with check (true);

grant select, insert, update on public.office_evaluations to anon;

-- ---------------------------------------------------------
-- Master data (institutes / faculties / career / program
-- options) was already publicly readable; no change needed
-- there. app_users / auth signup trigger are simply unused
-- now — left in place, harmless, in case auth is reintroduced
-- later.
-- ---------------------------------------------------------
