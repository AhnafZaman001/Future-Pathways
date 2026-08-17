-- =========================================================
-- closing_merit_records — actual 2025 closing-merit numbers
-- by university/campus/program. Distinct from merit_formulas
-- (which stores the WEIGHTAGE FORMULA — how merit is
-- calculated); this table stores the ACTUAL CUTOFF a real
-- admission cycle closed at. Neither replaces the other.
--
-- Run in order: this file, then closing_merit_seed_data.sql.
-- Safe to re-run (drops/recreates policies; seed file truncates
-- before reinserting).
-- =========================================================

create table if not exists public.closing_merit_records (
  id                          uuid primary key default gen_random_uuid(),
  institute_id                uuid references public.institutes(id),
  university_name_raw        text not null,
  campus                      text,
  program                      text not null,

  closing_merit_percentage  numeric,        -- NULL when data_status = 'not_found_in_current_scrape'
  admission_year              int not null,
  data_status                  text not null, -- e.g. "2025 final closing (reference)", "2025 first merit-list threshold", "not_found_in_current_scrape"

  source_type                  text not null check (source_type in ('official', 'third_party', 'not_found')),
  source_url                  text,
  notes                        text,

  active                        boolean not null default true,
  display_order                int not null default 0
);

-- Best-effort link to the institutes table by exact (case-
-- insensitive, trimmed) name match. Run after both institutes
-- and this table are seeded.
create or replace function public.link_closing_merit_to_institutes()
returns void
language sql
as $$
  update public.closing_merit_records cm
  set institute_id = i.id
  from public.institutes i
  where cm.institute_id is null
    and lower(trim(i.name)) = lower(trim(cm.university_name_raw));
$$;

alter table public.closing_merit_records enable row level security;

drop policy if exists "Anyone can read active closing merit records" on public.closing_merit_records;
create policy "Anyone can read active closing merit records"
  on public.closing_merit_records for select
  to anon, authenticated
  using (active = true or public.current_role() in ('counsellor','admin'));

drop policy if exists "Staff manage closing merit records" on public.closing_merit_records;
create policy "Staff manage closing merit records"
  on public.closing_merit_records for all
  to authenticated
  using (public.current_role() in ('counsellor','admin'))
  with check (public.current_role() in ('counsellor','admin'));

-- Data API grants — RLS alone doesn't expose a table to the Data API.
grant select on public.closing_merit_records to anon, authenticated;
grant insert, update, delete on public.closing_merit_records to authenticated;
