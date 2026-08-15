-- =========================================================
-- Future Pathways — student_submissions table
-- Run this once in Supabase Dashboard → SQL Editor → New query
-- =========================================================

create extension if not exists pgcrypto;

create table if not exists public.student_submissions (
  id                    uuid primary key default gen_random_uuid(),
  created_at            timestamptz not null default now(),

  student_name          text not null,

  matric_obtained        numeric not null,
  matric_total          numeric not null,
  fsc_obtained          numeric not null,
  fsc_total              numeric not null,

  field_of_study        text not null,
  area                  text not null,

  matric_pct            numeric,
  fsc_pct                numeric,
  provisional_score      numeric,
  provisional_ceiling    numeric
);

-- Lock the table down, then open ONLY inserts to the public (anon) key.
alter table public.student_submissions enable row level security;

drop policy if exists "Public can insert submissions" on public.student_submissions;

create policy "Public can insert submissions"
  on public.student_submissions
  for insert
  to anon
  with check (true);

-- No select / update / delete policy is defined for `anon` on purpose —
-- with RLS enabled, that means the public key can write but never read
-- back, edit, or delete rows. View submissions from the Table Editor in
-- the Supabase dashboard (that uses your account's full access, not RLS).
