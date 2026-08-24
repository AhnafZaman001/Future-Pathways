-- =========================================================
-- verify_and_fix_city_data.sql
--
-- Context: a college admin reported NUST showing up under
-- Faisalabad/Lahore/Karachi in the University Explorer's city
-- filter, and FAST-NUCES showing under a city it doesn't belong to.
--
-- Verified against multiple independent real-world sources (NUST's
-- own site, Wikipedia, and several university-guide sites):
--   NUST real campuses:        Islamabad, Rawalpindi, Risalpur, Karachi (PNEC), Quetta (NBC)
--   FAST-NUCES real campuses:  Islamabad, Lahore, Karachi, Peshawar, Chiniot-Faisalabad, Multan
--
-- These exactly match what's already in future_pathways_seed.sql --
-- "NUST at Karachi" is real data (their Navy-affiliated college),
-- not a bug. Neither has Faisalabad+Lahore both attributed to NUST
-- anywhere in this codebase's seed files.
--
-- Run PART 1 first and read the output -- it tells you whether the
-- live database actually matches the seed file or has drifted from
-- it. PART 2 is a corrective, idempotent UPDATE (safe to run
-- regardless of what PART 1 shows) that re-asserts the verified-
-- correct values either way.
-- =========================================================

-- ---------------------------------------------------------
-- PART 1: See what's actually live right now
-- ---------------------------------------------------------
select name, location, campuses
from public.institutes
where name in ('NUST', 'FAST-NUCES')
order by name;

-- ---------------------------------------------------------
-- PART 2: Re-assert the verified-correct values. Safe to run even
-- if PART 1 showed correct data already -- this just confirms it.
-- ---------------------------------------------------------
update public.institutes
set location = null,
    campuses = '{"Islamabad","Rawalpindi","Risalpur","Karachi","Quetta"}'
where name = 'NUST';

update public.institutes
set location = null,
    campuses = '{"Islamabad","Lahore","Karachi","Peshawar","Faisalabad","Multan"}'
where name = 'FAST-NUCES';

-- ---------------------------------------------------------
-- PART 3: Broader sanity sweep -- lists every engineering-pathway
-- institute with its full location/campuses, so anything else that
-- looks off (empty, wrong city, duplicate) is easy to spot at a
-- glance rather than guessing which one might be wrong next.
-- ---------------------------------------------------------
select name, location, campuses, pathway
from public.institutes
where pathway = 'engineering'
order by name;
