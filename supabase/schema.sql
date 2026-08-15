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

-- Lock the table down, then open inserts to both the public (anon) key
-- and signed-in users (authenticated) — index.html now requires login
-- via FP.requireAuth(), so inserts arrive as the `authenticated` role,
-- not `anon`. Both are granted so the table still works whether or not
-- a page in front of it requires a session.
alter table public.student_submissions enable row level security;

drop policy if exists "Public can insert submissions" on public.student_submissions;

create policy "Public can insert submissions"
  on public.student_submissions
  for insert
  to anon, authenticated
  with check (true);

-- IMPORTANT: RLS policies alone are not enough. Supabase's Data API
-- (PostgREST) only exposes tables that the role has an explicit
-- Postgres GRANT on — this is separate from RLS and easy to miss. Without
-- this line, every insert from the browser fails silently even though the
-- policy above looks correct.
grant insert on public.student_submissions to anon, authenticated;

-- No select / update / delete grant is given to `anon` on purpose — it
-- can write but never read back, edit, or delete rows. View submissions
-- from the Table Editor in the Supabase dashboard (that uses your
-- account's full access, not the anon role).
