-- =========================================================
-- merit_formulas — the merit calculation / entry-test guide
-- Run in order: this file, then merit_formulas_seed_data.sql
-- Safe to re-run (drops/recreates policies, truncates before reseed).
-- =========================================================

create table if not exists public.merit_formulas (
  id                uuid primary key default gen_random_uuid(),
  institute_id      uuid references public.institutes(id),
  institute_name_raw text not null,
  pathway            text not null check (pathway in ('engineering','medical')),

  basis              text,   -- e.g. "NET basis", "ACT/SAT basis", "ECAT-based"
  program_scope      text,   -- e.g. "Most NET UG", "BSCS / BSAI"

  formula_text        text not null,
  weightages_text    text,
  accepted_tests      text,
  effective_year      text,
  source_url          text,
  confidence          text,
  notes                text,

  active              boolean not null default true,
  display_order      int not null default 0
);

-- Best-effort link to the institutes table by exact (name, pathway) match.
-- Run this after both institutes and merit_formulas are seeded.
create or replace function public.link_merit_formulas_to_institutes()
returns void
language sql
as $$
  update public.merit_formulas mf
  set institute_id = i.id
  from public.institutes i
  where mf.institute_id is null
    and lower(trim(i.name)) = lower(trim(mf.institute_name_raw))
    and i.pathway = mf.pathway;
$$;

alter table public.merit_formulas enable row level security;

drop policy if exists "merit_formulas read" on public.merit_formulas;
create policy "merit_formulas read" on public.merit_formulas
  for select to authenticated using (active = true or public.is_staff());

drop policy if exists "merit_formulas write" on public.merit_formulas;
create policy "merit_formulas write" on public.merit_formulas
  for all to authenticated using (public.is_staff()) with check (public.is_staff());

-- Data API grant — RLS alone doesn't expose a table to the Data API.
grant select, insert, update, delete on public.merit_formulas to authenticated;
