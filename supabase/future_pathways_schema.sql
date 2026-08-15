-- =========================================================
-- Future Pathways feature — auth, roles, master data,
-- student submissions, preferences, office evaluations.
-- Run once in Supabase Dashboard → SQL Editor → New query.
-- Assumes supabase/schema.sql (student_submissions prototype
-- table) has already been run; this file is additive and does
-- not touch that table.
-- =========================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------
-- Roles
-- One row per authenticated user. security definer helper
-- avoids RLS-recursion when policies below need to check role.
-- ---------------------------------------------------------
create table if not exists public.app_users (
  id            uuid primary key references auth.users(id) on delete cascade,
  role          text not null default 'student' check (role in ('student','counsellor','admin')),
  full_name     text,
  created_at    timestamptz not null default now()
);

alter table public.app_users enable row level security;

create or replace function public.current_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role from public.app_users where id = auth.uid();
$$;

drop policy if exists "Users can view own app_user row" on public.app_users;
create policy "Users can view own app_user row"
  on public.app_users for select
  to authenticated
  using (id = auth.uid() or public.current_role() in ('counsellor','admin'));

drop policy if exists "Users can insert own app_user row" on public.app_users;
create policy "Users can insert own app_user row"
  on public.app_users for insert
  to authenticated
  with check (id = auth.uid());

-- New auth signups default to 'student' automatically.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.app_users (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', new.email));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------
-- Student profile (extends app_users, 1:1)
-- ---------------------------------------------------------
create table if not exists public.students (
  id                  uuid primary key references public.app_users(id) on delete cascade,
  student_name        text,
  father_name         text,
  father_profession   text,
  contact             text,
  discipline          text,
  section             text,
  roll_number         text,
  matric_marks        numeric,
  first_year_marks    numeric,
  updated_at          timestamptz not null default now()
);

alter table public.students enable row level security;

drop policy if exists "Student manages own profile" on public.students;
create policy "Student manages own profile"
  on public.students for all
  to authenticated
  using (id = auth.uid() or public.current_role() in ('counsellor','admin'))
  with check (id = auth.uid());

-- ---------------------------------------------------------
-- Master data: institutes, faculties, programs, careers.
-- Publicly readable (active rows only) so the form can list
-- them before/without a session; only counsellor/admin manage.
-- ---------------------------------------------------------
create table if not exists public.institutes (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  category       text not null check (category in ('engineering','medical','nums','private','other')),
  location       text,
  campuses       text[] default '{}',
  pathway        text not null check (pathway in ('engineering','medical')),
  active         boolean not null default true,
  display_order  integer not null default 0
);

create table if not exists public.fp_faculties (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  category       text,
  pathway        text not null check (pathway in ('engineering','medical')),
  active         boolean not null default true,
  display_order  integer not null default 0
);

create table if not exists public.program_options (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  category       text,
  pathway        text not null check (pathway in ('engineering','medical','both')),
  active         boolean not null default true,
  display_order  integer not null default 0
);

create table if not exists public.career_options (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  category       text,
  active         boolean not null default true,
  display_order  integer not null default 0
);

alter table public.institutes enable row level security;
alter table public.fp_faculties enable row level security;
alter table public.program_options enable row level security;
alter table public.career_options enable row level security;

drop policy if exists "Anyone can read active institutes" on public.institutes;
create policy "Anyone can read active institutes"
  on public.institutes for select
  to anon, authenticated
  using (active = true or public.current_role() in ('counsellor','admin'));

drop policy if exists "Staff manage institutes" on public.institutes;
create policy "Staff manage institutes"
  on public.institutes for insert
  to authenticated
  with check (public.current_role() in ('counsellor','admin'));
drop policy if exists "Staff update institutes" on public.institutes;
create policy "Staff update institutes"
  on public.institutes for update
  to authenticated
  using (public.current_role() in ('counsellor','admin'));
drop policy if exists "Staff delete institutes" on public.institutes;
create policy "Staff delete institutes"
  on public.institutes for delete
  to authenticated
  using (public.current_role() in ('counsellor','admin'));

drop policy if exists "Anyone can read active faculties" on public.fp_faculties;
create policy "Anyone can read active faculties"
  on public.fp_faculties for select
  to anon, authenticated
  using (active = true or public.current_role() in ('counsellor','admin'));
drop policy if exists "Staff manage faculties" on public.fp_faculties;
create policy "Staff manage faculties"
  on public.fp_faculties for all
  to authenticated
  using (public.current_role() in ('counsellor','admin'))
  with check (public.current_role() in ('counsellor','admin'));

drop policy if exists "Anyone can read active programs" on public.program_options;
create policy "Anyone can read active programs"
  on public.program_options for select
  to anon, authenticated
  using (active = true or public.current_role() in ('counsellor','admin'));
drop policy if exists "Staff manage programs" on public.program_options;
create policy "Staff manage programs"
  on public.program_options for all
  to authenticated
  using (public.current_role() in ('counsellor','admin'))
  with check (public.current_role() in ('counsellor','admin'));

drop policy if exists "Anyone can read active careers" on public.career_options;
create policy "Anyone can read active careers"
  on public.career_options for select
  to anon, authenticated
  using (active = true or public.current_role() in ('counsellor','admin'));
drop policy if exists "Staff manage careers" on public.career_options;
create policy "Staff manage careers"
  on public.career_options for all
  to authenticated
  using (public.current_role() in ('counsellor','admin'))
  with check (public.current_role() in ('counsellor','admin'));

grant select on public.institutes, public.fp_faculties, public.program_options, public.career_options to anon, authenticated;
grant insert, update, delete on public.institutes, public.fp_faculties, public.program_options, public.career_options to authenticated;
grant select, insert, update on public.app_users to authenticated;
grant select, insert, update on public.students to authenticated;

-- ---------------------------------------------------------
-- future_pathways — one submission (draft or submitted) per
-- student per pathway attempt. A partial unique index blocks
-- more than one *submitted* row per student (duplicate-submit
-- prevention); students can still keep exactly one open draft.
-- ---------------------------------------------------------
create table if not exists public.future_pathways (
  id                      uuid primary key default gen_random_uuid(),
  student_id              uuid not null references public.students(id) on delete cascade,
  pathway                 text not null check (pathway in ('engineering','medical')),
  status                  text not null default 'draft' check (status in ('draft','submitted')),
  additional_information  text,
  submitted_at            timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

create unique index if not exists one_draft_per_student
  on public.future_pathways (student_id)
  where status = 'draft';

create unique index if not exists one_submitted_per_student
  on public.future_pathways (student_id)
  where status = 'submitted';

alter table public.future_pathways enable row level security;

drop policy if exists "Student manages own draft" on public.future_pathways;
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

grant select, insert, update on public.future_pathways to authenticated;

-- ---------------------------------------------------------
-- Ranked preferences (institutes / faculties / programs)
-- ---------------------------------------------------------
create table if not exists public.student_institute_preferences (
  id                  uuid primary key default gen_random_uuid(),
  future_pathway_id   uuid not null references public.future_pathways(id) on delete cascade,
  preference_group    integer not null,
  rank                integer not null check (rank between 1 and 5),
  institute_id        uuid references public.institutes(id),
  custom_institute_name text,
  unique (future_pathway_id, preference_group, rank)
);

create table if not exists public.student_faculty_preferences (
  id                  uuid primary key default gen_random_uuid(),
  future_pathway_id   uuid not null references public.future_pathways(id) on delete cascade,
  preference_group    integer not null,
  rank                integer not null check (rank between 1 and 5),
  faculty_id          uuid references public.fp_faculties(id),
  custom_faculty_name text,
  unique (future_pathway_id, preference_group, rank)
);

create table if not exists public.student_program_preferences (
  id                  uuid primary key default gen_random_uuid(),
  future_pathway_id   uuid not null references public.future_pathways(id) on delete cascade,
  rank                integer not null check (rank between 1 and 5),
  program_id          uuid references public.program_options(id),
  custom_program_name text,
  unique (future_pathway_id, rank)
);

alter table public.student_institute_preferences enable row level security;
alter table public.student_faculty_preferences enable row level security;
alter table public.student_program_preferences enable row level security;

-- Ownership flows through future_pathways.student_id; only
-- editable while the parent submission is still a draft.
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

grant select, insert, update, delete on public.student_institute_preferences to authenticated;
grant select, insert, update, delete on public.student_faculty_preferences to authenticated;
grant select, insert, update, delete on public.student_program_preferences to authenticated;

-- ---------------------------------------------------------
-- office_evaluations — counsellor/admin only, students get
-- read-only visibility into their own once one exists.
-- ---------------------------------------------------------
create table if not exists public.office_evaluations (
  future_pathway_id   uuid primary key references public.future_pathways(id) on delete cascade,
  recommendation_1    text, recommendation_2  text, recommendation_3  text,
  recommendation_4    text, recommendation_5  text, recommendation_6  text,
  recommendation_7    text, recommendation_8  text, recommendation_9  text,
  recommendation_10   text, recommendation_11 text, recommendation_12 text,
  counsellor_name       text,
  counsellor_signature  text,
  principal              text,
  remarks                text,
  updated_at             timestamptz not null default now()
);

alter table public.office_evaluations enable row level security;

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

grant select, insert, update on public.office_evaluations to authenticated;

-- ---------------------------------------------------------
-- Bump updated_at automatically on future_pathways.
-- ---------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_future_pathways_updated_at on public.future_pathways;
create trigger set_future_pathways_updated_at
  before update on public.future_pathways
  for each row execute function public.set_updated_at();
