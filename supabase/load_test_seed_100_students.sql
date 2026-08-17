-- =========================================================
-- Load-test seed: 100 real students (from 1st Year Result 2026
-- Pre-Board), synthetic auth accounts + submitted Future Pathways
-- forms with randomized-but-valid ranked preferences.
--
-- v2 FIX: the first version of this file explicitly inserted into
-- public.app_users after creating the auth.users row -- but
-- on_auth_user_created (future_pathways_schema.sql) already fires
-- automatically on that insert and creates the app_users row
-- itself. The explicit insert then hit a duplicate-key conflict on
-- EVERY statement, rolling back the whole thing -- meaning v1
-- silently created zero students. This version removes that
-- redundant insert; public.students now chains directly off
-- new_user, and app_users is left entirely to the trigger.
--
-- PURPOSE: stress-test the app with realistic data volume, not to
-- represent real submissions. Every account uses a clearly-fake
-- @loadtest.rah.internal email so it can never be confused with a
-- real user and is trivial to bulk-delete -- see
-- load_test_cleanup.sql.
--
-- PRIVACY NOTE: student_name, section, roll_number, matric_marks,
-- and first_year_marks are real, taken directly from the school's
-- own uploaded results file. father_name, father_profession, and
-- contact are deliberately left NULL -- that data does not exist in
-- the source file and was not fabricated. first_year_marks is the
-- Pre-Board internal exam total (obtained marks), NOT the official
-- FSc Part 1 board result -- that isn't published yet per the source
-- file's own title. matric_marks is the raw obtained-marks figure
-- as recorded in the source file (not normalized to a percentage).
--
-- auth.users rows here are minimal and NOT login-capable -- no
-- auth.identities row, no real password hash. That's deliberate:
-- this is a data-volume/query-performance load test, not an
-- auth-flow test.
--
-- RECOMMENDED: run the first 3-5 student blocks first, check the
-- Table Editor for a clean result, THEN run the rest of the file.
-- This touches Supabase's internal auth schema directly and hasn't
-- been verified against this project's exact live schema.
-- =========================================================



-- ---- [1/100] MAHNOOR FATIMA (F3, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-mahnoor-fatima-f03-302@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MAHNOOR FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MAHNOOR FATIMA', 'Pre-Medical', 'F3', 'F03-302', 1066.0, 336.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BS (Hons)'),
    (1, 2, 'Pharm D'),
    (1, 3, 'MLT'),
    (1, 4, 'Others'),
    (1, 5, 'MBBS'),
    (2, 1, 'BDS'),
    (2, 2, 'Engineering & IT'),
    (2, 3, 'Others'),
    (2, 4, 'Pharm D'),
    (2, 5, 'DPT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'MBBS'),
    (2, 'Engineering & IT'),
    (3, 'DVM'),
    (4, 'Others'),
    (5, 'MLT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [2/100] SYEDA FATIMA GILLANI (F11, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-syeda-fatima-gillani-f11-1102@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"SYEDA FATIMA GILLANI"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'SYEDA FATIMA GILLANI', 'Pre-Medical', 'F11', 'F11-1102', 1170.0, 827.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MLT'),
    (1, 2, 'Others'),
    (1, 3, 'BDS'),
    (1, 4, 'MIT'),
    (1, 5, 'MBBS'),
    (2, 1, 'Engineering & IT'),
    (2, 2, 'MLT'),
    (2, 3, 'MBBS'),
    (2, 4, 'Others'),
    (2, 5, 'DPT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BDS'),
    (2, 'DVM'),
    (3, 'MBBS'),
    (4, 'DPT'),
    (5, 'MLT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [3/100] ZIMAL KAMRAN (F12, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-zimal-kamran-f12-1202@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ZIMAL KAMRAN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ZIMAL KAMRAN', 'Pre-Medical', 'F12', 'F12-1202', 1018.0, 598.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MLT'),
    (1, 2, 'MBBS'),
    (1, 3, 'DVM'),
    (1, 4, 'Engineering & IT'),
    (1, 5, 'DPT'),
    (2, 1, 'Pharm D'),
    (2, 2, 'DPT'),
    (2, 3, 'MLT'),
    (2, 4, 'BDS'),
    (2, 5, 'Engineering & IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BDS'),
    (2, 'DPT'),
    (3, 'Pharm D'),
    (4, 'MBBS'),
    (5, 'Engineering & IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [4/100] AREESHA FATIMA (F4, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-areesha-fatima-f04-401@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AREESHA FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AREESHA FATIMA', 'Pre-Medical', 'F4', 'F04-401', 1184.0, 688.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Others'),
    (1, 2, 'DVM'),
    (1, 3, 'BS (Hons)'),
    (1, 4, 'MBBS'),
    (1, 5, 'DPT'),
    (2, 1, 'BDS'),
    (2, 2, 'MBBS'),
    (2, 3, 'DVM'),
    (2, 4, 'MIT'),
    (2, 5, 'BS (Hons)')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Engineering & IT'),
    (2, 'MLT'),
    (3, 'BS (Hons)'),
    (4, 'DVM'),
    (5, 'DPT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [5/100] FARYAL RAI (F16 PM, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-faryal-rai-f16-16001@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FARYAL RAI"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FARYAL RAI', 'Pre-Medical', 'F16 PM', 'F16-16001', 882.0, 475.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MIT'),
    (1, 2, 'BS (Hons)'),
    (1, 3, 'DPT'),
    (1, 4, 'BDS'),
    (1, 5, 'MLT'),
    (2, 1, 'DVM'),
    (2, 2, 'BDS'),
    (2, 3, 'DPT'),
    (2, 4, 'MIT'),
    (2, 5, 'Others')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BS (Hons)'),
    (2, 'MIT'),
    (3, 'DPT'),
    (4, 'Engineering & IT'),
    (5, 'MBBS')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [6/100] INSHAL JAMIL (F2, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-inshal-jamil-f02-201@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"INSHAL JAMIL"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'INSHAL JAMIL', 'Pre-Medical', 'F2', 'F02-201', 1128.0, 558.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BDS'),
    (1, 2, 'Engineering & IT'),
    (1, 3, 'MLT'),
    (1, 4, 'Others'),
    (1, 5, 'Pharm D'),
    (2, 1, 'Pharm D'),
    (2, 2, 'MIT'),
    (2, 3, 'MLT'),
    (2, 4, 'MBBS'),
    (2, 5, 'BS (Hons)')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BDS'),
    (2, 'Engineering & IT'),
    (3, 'BS (Hons)'),
    (4, 'Pharm D'),
    (5, 'MIT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [7/100] AIMA ALI (F10 PM, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-aima-ali-f10-1001@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AIMA ALI"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AIMA ALI', 'Pre-Medical', 'F10 PM', 'F10-1001', 1118.0, 552.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BS (Hons)'),
    (1, 2, 'MIT'),
    (1, 3, 'Engineering & IT'),
    (1, 4, 'MBBS'),
    (1, 5, 'MLT'),
    (2, 1, 'DPT'),
    (2, 2, 'MIT'),
    (2, 3, 'BDS'),
    (2, 4, 'MBBS'),
    (2, 5, 'BS (Hons)')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'DPT'),
    (2, 'MIT'),
    (3, 'Others'),
    (4, 'BS (Hons)'),
    (5, 'DVM')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [8/100] MARYAM REHAN (F1A, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-maryam-rehan-f01-a-01@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MARYAM REHAN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MARYAM REHAN', 'Pre-Medical', 'F1A', 'F01-A-01', 1180.0, 867.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BS (Hons)'),
    (1, 2, 'MBBS'),
    (1, 3, 'MIT'),
    (1, 4, 'Pharm D'),
    (1, 5, 'BDS'),
    (2, 1, 'Others'),
    (2, 2, 'BDS'),
    (2, 3, 'MIT'),
    (2, 4, 'MBBS'),
    (2, 5, 'Engineering & IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'DPT'),
    (2, 'Pharm D'),
    (3, 'DVM'),
    (4, 'MIT'),
    (5, 'MLT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [9/100] ZAINAB RANA (F1B, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-zainab-rana-f01-b-101@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ZAINAB RANA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ZAINAB RANA', 'Pre-Medical', 'F1B', 'F01-B-101', 1154.0, 421.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MIT'),
    (1, 2, 'BDS'),
    (1, 3, 'Pharm D'),
    (1, 4, 'DVM'),
    (1, 5, 'MLT'),
    (2, 1, 'Engineering & IT'),
    (2, 2, 'DPT'),
    (2, 3, 'Pharm D'),
    (2, 4, 'MLT'),
    (2, 5, 'DVM')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Engineering & IT'),
    (2, 'DPT'),
    (3, 'MLT'),
    (4, 'Pharm D'),
    (5, 'BS (Hons)')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [10/100] TOOBA KASHIF (F3, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-tooba-kashif-f03-308@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"TOOBA KASHIF"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'TOOBA KASHIF', 'Pre-Medical', 'F3', 'F03-308', 1041.0, 385.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MLT'),
    (1, 2, 'DVM'),
    (1, 3, 'Pharm D'),
    (1, 4, 'MBBS'),
    (1, 5, 'BDS'),
    (2, 1, 'Pharm D'),
    (2, 2, 'DVM'),
    (2, 3, 'Engineering & IT'),
    (2, 4, 'MBBS'),
    (2, 5, 'MIT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Others'),
    (2, 'Pharm D'),
    (3, 'DPT'),
    (4, 'Engineering & IT'),
    (5, 'MBBS')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [11/100] MUBASHRA (F11, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-mubashra-f11-1106@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MUBASHRA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MUBASHRA', 'Pre-Medical', 'F11', 'F11-1106', 1158.0, 593.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Pharm D'),
    (1, 2, 'MLT'),
    (1, 3, 'BS (Hons)'),
    (1, 4, 'DPT'),
    (1, 5, 'Engineering & IT'),
    (2, 1, 'BS (Hons)'),
    (2, 2, 'Pharm D'),
    (2, 3, 'MBBS'),
    (2, 4, 'DVM'),
    (2, 5, 'Others')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Engineering & IT'),
    (2, 'MLT'),
    (3, 'Others'),
    (4, 'DVM'),
    (5, 'MIT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [12/100] MALAHA MAZHAR (F12, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-malaha-mazhar-f12-1205@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MALAHA MAZHAR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MALAHA MAZHAR', 'Pre-Medical', 'F12', 'F12-1205', 1004.0, 457.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BDS'),
    (1, 2, 'MIT'),
    (1, 3, 'MLT'),
    (1, 4, 'MBBS'),
    (1, 5, 'Others'),
    (2, 1, 'BDS'),
    (2, 2, 'DVM'),
    (2, 3, 'MIT'),
    (2, 4, 'Others'),
    (2, 5, 'MBBS')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BS (Hons)'),
    (2, 'MBBS'),
    (3, 'BDS'),
    (4, 'Engineering & IT'),
    (5, 'DPT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [13/100] ANIA ALI (F4, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-ania-ali-f04-404@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ANIA ALI"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ANIA ALI', 'Pre-Medical', 'F4', 'F04-404', 1158.0, 577.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Pharm D'),
    (1, 2, 'Engineering & IT'),
    (1, 3, 'BDS'),
    (1, 4, 'Others'),
    (1, 5, 'DPT'),
    (2, 1, 'MBBS'),
    (2, 2, 'BDS'),
    (2, 3, 'DVM'),
    (2, 4, 'DPT'),
    (2, 5, 'MIT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Pharm D'),
    (2, 'DPT'),
    (3, 'BS (Hons)'),
    (4, 'Engineering & IT'),
    (5, 'Others')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [14/100] ADEN FATIMA (F2, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-aden-fatima-f02-206@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ADEN FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ADEN FATIMA', 'Pre-Medical', 'F2', 'F02-206', 1118.0, 704.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MIT'),
    (1, 2, 'BDS'),
    (1, 3, 'Engineering & IT'),
    (1, 4, 'MLT'),
    (1, 5, 'DVM'),
    (2, 1, 'MIT'),
    (2, 2, 'Others'),
    (2, 3, 'Engineering & IT'),
    (2, 4, 'Pharm D'),
    (2, 5, 'MBBS')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Pharm D'),
    (2, 'BDS'),
    (3, 'BS (Hons)'),
    (4, 'MIT'),
    (5, 'Others')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [15/100] NOOR-UL-HUDA (F10 PM, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-noor-ul-huda-f10-1004@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"NOOR-UL-HUDA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'NOOR-UL-HUDA', 'Pre-Medical', 'F10 PM', 'F10-1004', 1088.0, 493.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MIT'),
    (1, 2, 'Pharm D'),
    (1, 3, 'MBBS'),
    (1, 4, 'BDS'),
    (1, 5, 'DPT'),
    (2, 1, 'BS (Hons)'),
    (2, 2, 'Pharm D'),
    (2, 3, 'MBBS'),
    (2, 4, 'MLT'),
    (2, 5, 'DPT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'DPT'),
    (2, 'BDS'),
    (3, 'Others'),
    (4, 'MIT'),
    (5, 'Pharm D')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [16/100] HIRA ASIM (F1A, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hira-asim-f01-a-04@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HIRA ASIM"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HIRA ASIM', 'Pre-Medical', 'F1A', 'F01-A-04', 1173.0, 691.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Pharm D'),
    (1, 2, 'BS (Hons)'),
    (1, 3, 'DVM'),
    (1, 4, 'DPT'),
    (1, 5, 'MLT'),
    (2, 1, 'Engineering & IT'),
    (2, 2, 'BS (Hons)'),
    (2, 3, 'DVM'),
    (2, 4, 'DPT'),
    (2, 5, 'BDS')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'DVM'),
    (2, 'MLT'),
    (3, 'Others'),
    (4, 'BDS'),
    (5, 'DPT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [17/100] MARIA QIBTIA (F1B, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-maria-qibtia-f01-b-104@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MARIA QIBTIA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MARIA QIBTIA', 'Pre-Medical', 'F1B', 'F01-B-104', 1145.0, 491.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MIT'),
    (1, 2, 'BS (Hons)'),
    (1, 3, 'MBBS'),
    (1, 4, 'Others'),
    (1, 5, 'Pharm D'),
    (2, 1, 'MIT'),
    (2, 2, 'DPT'),
    (2, 3, 'DVM'),
    (2, 4, 'BS (Hons)'),
    (2, 5, 'Engineering & IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BS (Hons)'),
    (2, 'MIT'),
    (3, 'Others'),
    (4, 'Pharm D'),
    (5, 'MBBS')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [18/100] EZZA ZAHEER (F3, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-ezza-zaheer-f03-311@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"EZZA ZAHEER"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'EZZA ZAHEER', 'Pre-Medical', 'F3', 'F03-311', 1034.0, 404.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'DVM'),
    (1, 2, 'BDS'),
    (1, 3, 'Others'),
    (1, 4, 'MIT'),
    (1, 5, 'Engineering & IT'),
    (2, 1, 'BS (Hons)'),
    (2, 2, 'DVM'),
    (2, 3, 'MIT'),
    (2, 4, 'DPT'),
    (2, 5, 'MLT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'MBBS'),
    (2, 'MIT'),
    (3, 'BS (Hons)'),
    (4, 'MLT'),
    (5, 'Engineering & IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [19/100] EMAN FATIMA (F11, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-eman-fatima-f11-1109@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"EMAN FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'EMAN FATIMA', 'Pre-Medical', 'F11', 'F11-1109', 1145.0, 500.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BDS'),
    (1, 2, 'Others'),
    (1, 3, 'MLT'),
    (1, 4, 'MIT'),
    (1, 5, 'BS (Hons)'),
    (2, 1, 'DVM'),
    (2, 2, 'MIT'),
    (2, 3, 'Pharm D'),
    (2, 4, 'Others'),
    (2, 5, 'BS (Hons)')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BS (Hons)'),
    (2, 'BDS'),
    (3, 'MLT'),
    (4, 'DVM'),
    (5, 'MIT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [20/100] QURATULAIN (F12, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-quratulain-f12-1209@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"QURATULAIN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'QURATULAIN', 'Pre-Medical', 'F12', 'F12-1209', 984.0, 532.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BDS'),
    (1, 2, 'Pharm D'),
    (1, 3, 'Engineering & IT'),
    (1, 4, 'Others'),
    (1, 5, 'MBBS'),
    (2, 1, 'Pharm D'),
    (2, 2, 'MIT'),
    (2, 3, 'Others'),
    (2, 4, 'DPT'),
    (2, 5, 'MLT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'MIT'),
    (2, 'BS (Hons)'),
    (3, 'Pharm D'),
    (4, 'DPT'),
    (5, 'MLT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [21/100] ZAINAB SHAHZAD (F4, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-zainab-shahzad-f04-407@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ZAINAB SHAHZAD"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ZAINAB SHAHZAD', 'Pre-Medical', 'F4', 'F04-407', 1040.0, 626.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Pharm D'),
    (1, 2, 'MBBS'),
    (1, 3, 'Engineering & IT'),
    (1, 4, 'MLT'),
    (1, 5, 'BS (Hons)'),
    (2, 1, 'BDS'),
    (2, 2, 'Engineering & IT'),
    (2, 3, 'Pharm D'),
    (2, 4, 'DVM'),
    (2, 5, 'Others')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'DVM'),
    (2, 'MBBS'),
    (3, 'DPT'),
    (4, 'BDS'),
    (5, 'Pharm D')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [22/100] AMINA SHAHID (F16 PM, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-amina-shahid-f16-16007@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AMINA SHAHID"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AMINA SHAHID', 'Pre-Medical', 'F16 PM', 'F16-16007', 1032.0, 645.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Engineering & IT'),
    (1, 2, 'DVM'),
    (1, 3, 'BS (Hons)'),
    (1, 4, 'Pharm D'),
    (1, 5, 'DPT'),
    (2, 1, 'MLT'),
    (2, 2, 'Pharm D'),
    (2, 3, 'MBBS'),
    (2, 4, 'BS (Hons)'),
    (2, 5, 'Engineering & IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'MIT'),
    (2, 'Engineering & IT'),
    (3, 'MLT'),
    (4, 'Others'),
    (5, 'DPT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [23/100] MAHAM IRFAN (F2, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-maham-irfan-f02-210@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MAHAM IRFAN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MAHAM IRFAN', 'Pre-Medical', 'F2', 'F02-210', 1103.0, 549.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Pharm D'),
    (1, 2, 'Engineering & IT'),
    (1, 3, 'Others'),
    (1, 4, 'DPT'),
    (1, 5, 'MLT'),
    (2, 1, 'MBBS'),
    (2, 2, 'MIT'),
    (2, 3, 'Pharm D'),
    (2, 4, 'DPT'),
    (2, 5, 'Others')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Pharm D'),
    (2, 'Others'),
    (3, 'Engineering & IT'),
    (4, 'DVM'),
    (5, 'DPT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [24/100] MEERAB NAZIR (F10 PM, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-meerab-nazir-f10-1009@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MEERAB NAZIR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MEERAB NAZIR', 'Pre-Medical', 'F10 PM', 'F10-1009', 970.0, 539.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BDS'),
    (1, 2, 'Engineering & IT'),
    (1, 3, 'MBBS'),
    (1, 4, 'Pharm D'),
    (1, 5, 'BS (Hons)'),
    (2, 1, 'Engineering & IT'),
    (2, 2, 'Others'),
    (2, 3, 'MIT'),
    (2, 4, 'MLT'),
    (2, 5, 'MBBS')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Engineering & IT'),
    (2, 'MBBS'),
    (3, 'DVM'),
    (4, 'BDS'),
    (5, 'Pharm D')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [25/100] JAVERIA AZAM (F1A, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-javeria-azam-f01-a-07@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"JAVERIA AZAM"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'JAVERIA AZAM', 'Pre-Medical', 'F1A', 'F01-A-07', 1171.0, 668.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MBBS'),
    (1, 2, 'BDS'),
    (1, 3, 'MIT'),
    (1, 4, 'DPT'),
    (1, 5, 'Others'),
    (2, 1, 'BDS'),
    (2, 2, 'MIT'),
    (2, 3, 'BS (Hons)'),
    (2, 4, 'DPT'),
    (2, 5, 'MLT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Others'),
    (2, 'Engineering & IT'),
    (3, 'DVM'),
    (4, 'BS (Hons)'),
    (5, 'Pharm D')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [26/100] MEERAB FATIMA (F1B, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-meerab-fatima-f01-b-107@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MEERAB FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MEERAB FATIMA', 'Pre-Medical', 'F1B', 'F01-B-107', 1144.0, 593.5 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'MIT'),
    (1, 2, 'Engineering & IT'),
    (1, 3, 'Others'),
    (1, 4, 'DPT'),
    (1, 5, 'BDS'),
    (2, 1, 'Engineering & IT'),
    (2, 2, 'DPT'),
    (2, 3, 'DVM'),
    (2, 4, 'MLT'),
    (2, 5, 'MIT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Pharm D'),
    (2, 'MLT'),
    (3, 'BDS'),
    (4, 'DVM'),
    (5, 'Engineering & IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [27/100] ZOHA (F3, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-zoha-f03-315@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ZOHA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ZOHA', 'Pre-Medical', 'F3', 'F03-315', 1031.0, 359.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BS (Hons)'),
    (1, 2, 'BDS'),
    (1, 3, 'DVM'),
    (1, 4, 'MIT'),
    (1, 5, 'MBBS'),
    (2, 1, 'DVM'),
    (2, 2, 'DPT'),
    (2, 3, 'BDS'),
    (2, 4, 'MLT'),
    (2, 5, 'MIT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BS (Hons)'),
    (2, 'Pharm D'),
    (3, 'DPT'),
    (4, 'BDS'),
    (5, 'DVM')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [28/100] HIBA FURQAN (F11, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hiba-furqan-f11-1112@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HIBA FURQAN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HIBA FURQAN', 'Pre-Medical', 'F11', 'F11-1112', 1131.0, 781.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'DVM'),
    (1, 2, 'BDS'),
    (1, 3, 'MLT'),
    (1, 4, 'Others'),
    (1, 5, 'Engineering & IT'),
    (2, 1, 'DVM'),
    (2, 2, 'Pharm D'),
    (2, 3, 'MLT'),
    (2, 4, 'DPT'),
    (2, 5, 'Others')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'BS (Hons)'),
    (2, 'MLT'),
    (3, 'DVM'),
    (4, 'Pharm D'),
    (5, 'Engineering & IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [29/100] EMAAN AMIIR (F12, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-emaan-amiir-f12-1212@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"EMAAN AMIIR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'EMAAN AMIIR', 'Pre-Medical', 'F12', 'F12-1212', 969.0, 356.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BDS'),
    (1, 2, 'BS (Hons)'),
    (1, 3, 'MBBS'),
    (1, 4, 'Pharm D'),
    (1, 5, 'DPT'),
    (2, 1, 'MIT'),
    (2, 2, 'Others'),
    (2, 3, 'MBBS'),
    (2, 4, 'DVM'),
    (2, 5, 'Pharm D')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Engineering & IT'),
    (2, 'DPT'),
    (3, 'BDS'),
    (4, 'MBBS'),
    (5, 'MIT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [30/100] RAMISHA AMIR (F4, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-ramisha-amir-f04-410@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"RAMISHA AMIR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'RAMISHA AMIR', 'Pre-Medical', 'F4', 'F04-410', 1111.0, 485.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'BDS'),
    (1, 2, 'Others'),
    (1, 3, 'DPT'),
    (1, 4, 'Pharm D'),
    (1, 5, 'MBBS'),
    (2, 1, 'Pharm D'),
    (2, 2, 'DPT'),
    (2, 3, 'Others'),
    (2, 4, 'MLT'),
    (2, 5, 'DVM')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'DPT'),
    (2, 'MLT'),
    (3, 'Pharm D'),
    (4, 'Others'),
    (5, 'Engineering & IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [31/100] NOOR UL AIN (F2, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-noor-ul-ain-f02-215@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"NOOR UL AIN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'NOOR UL AIN', 'Pre-Medical', 'F2', 'F02-215', 1095.0, 616.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Others'),
    (1, 2, 'MIT'),
    (1, 3, 'BS (Hons)'),
    (1, 4, 'MBBS'),
    (1, 5, 'Pharm D'),
    (2, 1, 'MBBS'),
    (2, 2, 'Pharm D'),
    (2, 3, 'MLT'),
    (2, 4, 'Others'),
    (2, 5, 'Engineering & IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'MBBS'),
    (2, 'BDS'),
    (3, 'DPT'),
    (4, 'Others'),
    (5, 'MIT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [32/100] ZAINAB IMRAN (F10 PM, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-zainab-imran-f10-1012@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ZAINAB IMRAN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ZAINAB IMRAN', 'Pre-Medical', 'F10 PM', 'F10-1012', 784.0, 470.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'DVM'),
    (1, 2, 'BDS'),
    (1, 3, 'DPT'),
    (1, 4, 'MLT'),
    (1, 5, 'MBBS'),
    (2, 1, 'MIT'),
    (2, 2, 'MBBS'),
    (2, 3, 'BS (Hons)'),
    (2, 4, 'DPT'),
    (2, 5, 'DVM')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'DPT'),
    (2, 'Pharm D'),
    (3, 'MBBS'),
    (4, 'Others'),
    (5, 'BS (Hons)')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [33/100] HAMNA NOOR (F1A, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hamna-noor-f01-a-10@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HAMNA NOOR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HAMNA NOOR', 'Pre-Medical', 'F1A', 'F01-A-10', 1167.0, 780.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'DVM'),
    (1, 2, 'BDS'),
    (1, 3, 'Pharm D'),
    (1, 4, 'MIT'),
    (1, 5, 'MBBS'),
    (2, 1, 'Pharm D'),
    (2, 2, 'DVM'),
    (2, 3, 'DPT'),
    (2, 4, 'BS (Hons)'),
    (2, 5, 'Others')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Engineering & IT'),
    (2, 'DVM'),
    (3, 'DPT'),
    (4, 'Others'),
    (5, 'MIT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [34/100] IZZA SHAHZAD (F1B, Pre-Medical) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-izza-shahzad-f01-b-110@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"IZZA SHAHZAD"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'IZZA SHAHZAD', 'Pre-Medical', 'F1B', 'F01-B-110', 1138.0, 561.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'medical', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, grp.g, ranked.rnk, ranked.id
  from new_fp,
    (values
    (1),
    (2)
    ) as grp(g),
    lateral (
      select id, row_number() over (order by random()) as rnk
      from public.institutes where pathway = 'medical'
      limit 5
    ) as ranked
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Pharm D'),
    (1, 2, 'DPT'),
    (1, 3, 'BS (Hons)'),
    (1, 4, 'MLT'),
    (1, 5, 'MBBS'),
    (2, 1, 'DPT'),
    (2, 2, 'MBBS'),
    (2, 3, 'Engineering & IT'),
    (2, 4, 'MIT'),
    (2, 5, 'BS (Hons)')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'medical'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Engineering & IT'),
    (2, 'Others'),
    (3, 'DVM'),
    (4, 'DPT'),
    (5, 'MIT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'medical';

-- ---- [35/100] TAHREEM RIAZ (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-tahreem-riaz-f13-pe-1301@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"TAHREEM RIAZ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'TAHREEM RIAZ', 'Pre-Engineering', 'F13 PE', 'F13-PE-1301', 1172.0, 507.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'FAST-NUCES'),
    (1, 2, 'International Islamic University'),
    (1, 3, 'Other'),
    (1, 4, 'UET Taxila / Chakwal'),
    (1, 5, 'PIFD'),
    (2, 1, 'GIK'),
    (2, 2, 'NUST'),
    (2, 3, 'FAST-NUCES'),
    (2, 4, 'Quaid-i-Azam University'),
    (2, 5, 'NCA'),
    (3, 1, 'Namal'),
    (3, 2, 'Quaid-i-Azam University'),
    (3, 3, 'COMSATS'),
    (3, 4, 'LSE'),
    (3, 5, 'Punjab University Engineering Programs'),
    (4, 1, 'Bahria University'),
    (4, 2, 'COMSATS'),
    (4, 3, 'NUST'),
    (4, 4, 'NTU'),
    (4, 5, 'GIK')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Petroleum'),
    (1, 2, 'Polymer'),
    (1, 3, 'Civil'),
    (1, 4, 'Agricultural'),
    (1, 5, 'Aeronautical'),
    (2, 1, 'Biomedical'),
    (2, 2, 'Agricultural'),
    (2, 3, 'Textile'),
    (2, 4, 'Aerospace'),
    (2, 5, 'Mining'),
    (3, 1, 'Telecommunication'),
    (3, 2, 'Environmental'),
    (3, 3, 'Other'),
    (3, 4, 'Architectural'),
    (3, 5, 'Petroleum'),
    (4, 1, 'Metallurgical'),
    (4, 2, 'Architectural'),
    (4, 3, 'Other'),
    (4, 4, 'Aeronautical'),
    (4, 5, 'Architecture')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'Artificial Intelligence'),
    (3, 'Computer Science'),
    (4, 'Computer Engineering'),
    (5, 'Other')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [36/100] AREEBA ZAHID (F9 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-areeba-zahid-f09-pe-972@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AREEBA ZAHID"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AREEBA ZAHID', 'Pre-Engineering', 'F9 PE', 'F09-PE-972', 1110.0, 686.5 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'UET Taxila / Chakwal'),
    (1, 2, 'FAST-NUCES'),
    (1, 3, 'UET Lahore'),
    (1, 4, 'NCA'),
    (1, 5, 'NASTP'),
    (2, 1, 'NUST'),
    (2, 2, 'NCA'),
    (2, 3, 'LUMS'),
    (2, 4, 'COMSATS'),
    (2, 5, 'International Islamic University'),
    (3, 1, 'Punjab University Engineering Programs'),
    (3, 2, 'FAST-NUCES'),
    (3, 3, 'NASTP'),
    (3, 4, 'Namal'),
    (3, 5, 'UET Lahore'),
    (4, 1, 'Quaid-i-Azam University'),
    (4, 2, 'Bahria University'),
    (4, 3, 'LSE'),
    (4, 4, 'NCA'),
    (4, 5, 'IBA')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Chemical'),
    (1, 2, 'Industrial & Manufacturing'),
    (1, 3, 'Polymer'),
    (1, 4, 'Electrical'),
    (1, 5, 'Transportation'),
    (2, 1, 'Metallurgical'),
    (2, 2, 'Aerospace'),
    (2, 3, 'Petroleum'),
    (2, 4, 'Mechatronics'),
    (2, 5, 'Environmental'),
    (3, 1, 'Architectural'),
    (3, 2, 'Transportation'),
    (3, 3, 'Chemical'),
    (3, 4, 'Electrical'),
    (3, 5, 'Metallurgical'),
    (4, 1, 'Mining'),
    (4, 2, 'Mechanical'),
    (4, 3, 'Textile'),
    (4, 4, 'Industrial & Manufacturing'),
    (4, 5, 'Telecommunication')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Hardware Engineering'),
    (2, 'Other'),
    (3, 'Software Engineering'),
    (4, 'Computer Science'),
    (5, 'Artificial Intelligence')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [37/100] HAJRA EMAN SAEED (F10 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hajra-eman-saeed-f10-pe-1041@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HAJRA EMAN SAEED"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HAJRA EMAN SAEED', 'Pre-Engineering', 'F10 PE', 'F10-PE-1041', 1136.0, 744.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'International Islamic University'),
    (1, 2, 'ITU'),
    (1, 3, 'PIEAS'),
    (1, 4, 'NCA'),
    (1, 5, 'NTU'),
    (2, 1, 'Air University'),
    (2, 2, 'NUST'),
    (2, 3, 'International Islamic University'),
    (2, 4, 'LUMS'),
    (2, 5, 'Quaid-i-Azam University'),
    (3, 1, 'Punjab University Engineering Programs'),
    (3, 2, 'IST'),
    (3, 3, 'UET Taxila / Chakwal'),
    (3, 4, 'LUMS'),
    (3, 5, 'NTU'),
    (4, 1, 'FAST-NUCES'),
    (4, 2, 'Other'),
    (4, 3, 'Namal'),
    (4, 4, 'Air University'),
    (4, 5, 'Quaid-i-Azam University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Textile'),
    (1, 2, 'Architecture'),
    (1, 3, 'Environmental'),
    (1, 4, 'Avionics'),
    (1, 5, 'Aeronautical'),
    (2, 1, 'Architecture'),
    (2, 2, 'Mechatronics'),
    (2, 3, 'Other'),
    (2, 4, 'Telecommunication'),
    (2, 5, 'Aeronautical'),
    (3, 1, 'Biomedical'),
    (3, 2, 'Other'),
    (3, 3, 'Telecommunication'),
    (3, 4, 'Architecture'),
    (3, 5, 'Electronics'),
    (4, 1, 'Electrical'),
    (4, 2, 'Agricultural'),
    (4, 3, 'Electronics'),
    (4, 4, 'Other'),
    (4, 5, 'Aeronautical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Hardware Engineering'),
    (2, 'Computer Engineering'),
    (3, 'Computer Science'),
    (4, 'Cybersecurity'),
    (5, 'Data Sciences')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [38/100] ANAYA MUDASSAR (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-anaya-mudassar-f06-pe-601@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ANAYA MUDASSAR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ANAYA MUDASSAR', 'Pre-Engineering', 'F6 PE', 'F06-PE-601', 1154.0, 812.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'LSE'),
    (1, 2, 'NASTP'),
    (1, 3, 'UET Lahore'),
    (1, 4, 'LUMS'),
    (1, 5, 'IST'),
    (2, 1, 'NUST'),
    (2, 2, 'IST'),
    (2, 3, 'UET Taxila / Chakwal'),
    (2, 4, 'Quaid-i-Azam University'),
    (2, 5, 'PIEAS'),
    (3, 1, 'Bahria University'),
    (3, 2, 'Punjab University/PUCIT'),
    (3, 3, 'Quaid-i-Azam University'),
    (3, 4, 'IST'),
    (3, 5, 'COMSATS'),
    (4, 1, 'Bahria University'),
    (4, 2, 'Namal'),
    (4, 3, 'COMSATS'),
    (4, 4, 'NTU'),
    (4, 5, 'PIEAS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Telecommunication'),
    (1, 2, 'Mechanical'),
    (1, 3, 'Textile'),
    (1, 4, 'Industrial & Manufacturing'),
    (1, 5, 'Petroleum'),
    (2, 1, 'Architectural'),
    (2, 2, 'Petroleum'),
    (2, 3, 'Aeronautical'),
    (2, 4, 'Polymer'),
    (2, 5, 'Textile'),
    (3, 1, 'Mining'),
    (3, 2, 'Mechanical'),
    (3, 3, 'Textile'),
    (3, 4, 'Agricultural'),
    (3, 5, 'Environmental'),
    (4, 1, 'Mechatronics'),
    (4, 2, 'Avionics'),
    (4, 3, 'Aeronautical'),
    (4, 4, 'Architectural'),
    (4, 5, 'Mechanical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Artificial Intelligence'),
    (3, 'Other'),
    (4, 'Data Sciences'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [39/100] KHADIJA IJAZ (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-khadija-ijaz-f13-pe-1304@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"KHADIJA IJAZ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'KHADIJA IJAZ', 'Pre-Engineering', 'F13 PE', 'F13-PE-1304', 1155.0, 787.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'UET Taxila / Chakwal'),
    (1, 2, 'PIEAS'),
    (1, 3, 'Bahria University'),
    (1, 4, 'ITU'),
    (1, 5, 'Punjab University Engineering Programs'),
    (2, 1, 'IST'),
    (2, 2, 'NCA'),
    (2, 3, 'LUMS'),
    (2, 4, 'GIK'),
    (2, 5, 'Quaid-i-Azam University'),
    (3, 1, 'NTU'),
    (3, 2, 'NCA'),
    (3, 3, 'COMSATS'),
    (3, 4, 'Other'),
    (3, 5, 'UET Lahore'),
    (4, 1, 'PIFD'),
    (4, 2, 'ITU'),
    (4, 3, 'NCA'),
    (4, 4, 'IBA'),
    (4, 5, 'PIEAS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Aerospace'),
    (1, 2, 'Architectural'),
    (1, 3, 'Environmental'),
    (1, 4, 'Mechanical'),
    (1, 5, 'Textile'),
    (2, 1, 'Electrical'),
    (2, 2, 'Environmental'),
    (2, 3, 'Polymer'),
    (2, 4, 'Mechanical'),
    (2, 5, 'Telecommunication'),
    (3, 1, 'Polymer'),
    (3, 2, 'Industrial & Manufacturing'),
    (3, 3, 'Mining'),
    (3, 4, 'Architectural'),
    (3, 5, 'Mechanical'),
    (4, 1, 'Electronics'),
    (4, 2, 'Mechanical'),
    (4, 3, 'Architecture'),
    (4, 4, 'Telecommunication'),
    (4, 5, 'Industrial & Manufacturing')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Artificial Intelligence'),
    (2, 'IT'),
    (3, 'Software Engineering'),
    (4, 'Other'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [40/100] MALEEHA NOOR (F10 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-maleeha-noor-f10-pe-1044@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MALEEHA NOOR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MALEEHA NOOR', 'Pre-Engineering', 'F10 PE', 'F10-PE-1044', 1160.0, 772.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'IBA'),
    (1, 2, 'Punjab University/PUCIT'),
    (1, 3, 'ITU'),
    (1, 4, 'PIFD'),
    (1, 5, 'LUMS'),
    (2, 1, 'International Islamic University'),
    (2, 2, 'NCA'),
    (2, 3, 'Air University'),
    (2, 4, 'Punjab University/PUCIT'),
    (2, 5, 'Other'),
    (3, 1, 'FAST-NUCES'),
    (3, 2, 'NUST'),
    (3, 3, 'Other'),
    (3, 4, 'PIFD'),
    (3, 5, 'NTU'),
    (4, 1, 'LSE'),
    (4, 2, 'UET Lahore'),
    (4, 3, 'International Islamic University'),
    (4, 4, 'COMSATS'),
    (4, 5, 'IST')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Metallurgical'),
    (1, 2, 'Electrical'),
    (1, 3, 'Mining'),
    (1, 4, 'Civil'),
    (1, 5, 'Architectural'),
    (2, 1, 'Other'),
    (2, 2, 'Electrical'),
    (2, 3, 'Environmental'),
    (2, 4, 'Industrial & Manufacturing'),
    (2, 5, 'Transportation'),
    (3, 1, 'Mechanical'),
    (3, 2, 'Mining'),
    (3, 3, 'Electronics'),
    (3, 4, 'Transportation'),
    (3, 5, 'Biomedical'),
    (4, 1, 'Industrial & Manufacturing'),
    (4, 2, 'Mechatronics'),
    (4, 3, 'Civil'),
    (4, 4, 'Agricultural'),
    (4, 5, 'Environmental')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Hardware Engineering'),
    (3, 'Other'),
    (4, 'Data Sciences'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [41/100] AYESHA WASEEM (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-ayesha-waseem-f06-pe-604@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AYESHA WASEEM"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AYESHA WASEEM', 'Pre-Engineering', 'F6 PE', 'F06-PE-604', 1137.0, 685.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'IST'),
    (1, 2, 'Air University'),
    (1, 3, 'Punjab University Engineering Programs'),
    (1, 4, 'NTU'),
    (1, 5, 'IBA'),
    (2, 1, 'NTU'),
    (2, 2, 'PIFD'),
    (2, 3, 'UET Lahore'),
    (2, 4, 'Air University'),
    (2, 5, 'Punjab University/PUCIT'),
    (3, 1, 'Punjab University Engineering Programs'),
    (3, 2, 'FAST-NUCES'),
    (3, 3, 'GIK'),
    (3, 4, 'IBA'),
    (3, 5, 'Air University'),
    (4, 1, 'FAST-NUCES'),
    (4, 2, 'IBA'),
    (4, 3, 'Punjab University Engineering Programs'),
    (4, 4, 'ITU'),
    (4, 5, 'UET Taxila / Chakwal')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Mechatronics'),
    (1, 2, 'Aerospace'),
    (1, 3, 'Architecture'),
    (1, 4, 'Chemical'),
    (1, 5, 'Textile'),
    (2, 1, 'Biomedical'),
    (2, 2, 'Metallurgical'),
    (2, 3, 'Environmental'),
    (2, 4, 'Industrial & Manufacturing'),
    (2, 5, 'Aeronautical'),
    (3, 1, 'Industrial & Manufacturing'),
    (3, 2, 'Mining'),
    (3, 3, 'Aeronautical'),
    (3, 4, 'Petroleum'),
    (3, 5, 'Environmental'),
    (4, 1, 'Textile'),
    (4, 2, 'Aerospace'),
    (4, 3, 'Agricultural'),
    (4, 4, 'Mining'),
    (4, 5, 'Civil')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Other'),
    (3, 'Computer Science'),
    (4, 'Computer Engineering'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [42/100] FAIQA KASHIF (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-faiqa-kashif-f13-pe-1307@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FAIQA KASHIF"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FAIQA KASHIF', 'Pre-Engineering', 'F13 PE', 'F13-PE-1307', 1090.0, 0.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NCA'),
    (1, 2, 'International Islamic University'),
    (1, 3, 'NTU'),
    (1, 4, 'PIFD'),
    (1, 5, 'COMSATS'),
    (2, 1, 'LUMS'),
    (2, 2, 'UET Lahore'),
    (2, 3, 'NUST'),
    (2, 4, 'PIFD'),
    (2, 5, 'Bahria University'),
    (3, 1, 'IST'),
    (3, 2, 'NASTP'),
    (3, 3, 'LUMS'),
    (3, 4, 'FAST-NUCES'),
    (3, 5, 'NCA'),
    (4, 1, 'Namal'),
    (4, 2, 'NTU'),
    (4, 3, 'Punjab University Engineering Programs'),
    (4, 4, 'PIEAS'),
    (4, 5, 'UET Lahore')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Electronics'),
    (1, 2, 'Architectural'),
    (1, 3, 'Electrical'),
    (1, 4, 'Biomedical'),
    (1, 5, 'Mining'),
    (2, 1, 'Biomedical'),
    (2, 2, 'Telecommunication'),
    (2, 3, 'Architectural'),
    (2, 4, 'Mining'),
    (2, 5, 'Industrial & Manufacturing'),
    (3, 1, 'Metallurgical'),
    (3, 2, 'Mechatronics'),
    (3, 3, 'Textile'),
    (3, 4, 'Industrial & Manufacturing'),
    (3, 5, 'Electronics'),
    (4, 1, 'Transportation'),
    (4, 2, 'Architecture'),
    (4, 3, 'Agricultural'),
    (4, 4, 'Telecommunication'),
    (4, 5, 'Aeronautical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Hardware Engineering'),
    (2, 'Computer Engineering'),
    (3, 'IT'),
    (4, 'Data Sciences'),
    (5, 'Other')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [43/100] FATIMA SHOAIB (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-fatima-shoaib-f06-pe-608@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FATIMA SHOAIB"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FATIMA SHOAIB', 'Pre-Engineering', 'F6 PE', 'F06-PE-608', 1128.0, 794.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'FAST-NUCES'),
    (1, 2, 'COMSATS'),
    (1, 3, 'Namal'),
    (1, 4, 'NASTP'),
    (1, 5, 'Punjab University/PUCIT'),
    (2, 1, 'NCA'),
    (2, 2, 'UET Taxila / Chakwal'),
    (2, 3, 'Punjab University Engineering Programs'),
    (2, 4, 'LSE'),
    (2, 5, 'LUMS'),
    (3, 1, 'LUMS'),
    (3, 2, 'Air University'),
    (3, 3, 'COMSATS'),
    (3, 4, 'NTU'),
    (3, 5, 'UET Taxila / Chakwal'),
    (4, 1, 'IBA'),
    (4, 2, 'International Islamic University'),
    (4, 3, 'Punjab University Engineering Programs'),
    (4, 4, 'IST'),
    (4, 5, 'Namal')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Architecture'),
    (1, 2, 'Telecommunication'),
    (1, 3, 'Agricultural'),
    (1, 4, 'Civil'),
    (1, 5, 'Other'),
    (2, 1, 'Aeronautical'),
    (2, 2, 'Polymer'),
    (2, 3, 'Mechanical'),
    (2, 4, 'Aerospace'),
    (2, 5, 'Mechatronics'),
    (3, 1, 'Electrical'),
    (3, 2, 'Architecture'),
    (3, 3, 'Petroleum'),
    (3, 4, 'Electronics'),
    (3, 5, 'Mechatronics'),
    (4, 1, 'Aeronautical'),
    (4, 2, 'Other'),
    (4, 3, 'Environmental'),
    (4, 4, 'Architecture'),
    (4, 5, 'Industrial & Manufacturing')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Cybersecurity'),
    (3, 'Artificial Intelligence'),
    (4, 'Computer Science'),
    (5, 'Data Sciences')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [44/100] FAIQA WAQAR (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-faiqa-waqar-f13-pe-1310@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FAIQA WAQAR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FAIQA WAQAR', 'Pre-Engineering', 'F13 PE', 'F13-PE-1310', 1045.0, 444.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Bahria University'),
    (1, 2, 'PIFD'),
    (1, 3, 'ITU'),
    (1, 4, 'Quaid-i-Azam University'),
    (1, 5, 'NCA'),
    (2, 1, 'Punjab University/PUCIT'),
    (2, 2, 'LUMS'),
    (2, 3, 'COMSATS'),
    (2, 4, 'Other'),
    (2, 5, 'Namal'),
    (3, 1, 'FAST-NUCES'),
    (3, 2, 'Punjab University/PUCIT'),
    (3, 3, 'IST'),
    (3, 4, 'COMSATS'),
    (3, 5, 'Punjab University Engineering Programs'),
    (4, 1, 'NTU'),
    (4, 2, 'Punjab University Engineering Programs'),
    (4, 3, 'UET Taxila / Chakwal'),
    (4, 4, 'COMSATS'),
    (4, 5, 'PIEAS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Petroleum'),
    (1, 2, 'Aerospace'),
    (1, 3, 'Electrical'),
    (1, 4, 'Biomedical'),
    (1, 5, 'Other'),
    (2, 1, 'Aeronautical'),
    (2, 2, 'Environmental'),
    (2, 3, 'Mechatronics'),
    (2, 4, 'Electrical'),
    (2, 5, 'Architectural'),
    (3, 1, 'Textile'),
    (3, 2, 'Agricultural'),
    (3, 3, 'Aeronautical'),
    (3, 4, 'Biomedical'),
    (3, 5, 'Mechanical'),
    (4, 1, 'Industrial & Manufacturing'),
    (4, 2, 'Petroleum'),
    (4, 3, 'Agricultural'),
    (4, 4, 'Biomedical'),
    (4, 5, 'Transportation')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Hardware Engineering'),
    (2, 'Data Sciences'),
    (3, 'Computer Science'),
    (4, 'Artificial Intelligence'),
    (5, 'IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [45/100] HANIA MUSHTAQ (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hania-mushtaq-f06-pe-611@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HANIA MUSHTAQ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HANIA MUSHTAQ', 'Pre-Engineering', 'F6 PE', 'F06-PE-611', 1115.0, 646.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'GIK'),
    (1, 2, 'IBA'),
    (1, 3, 'Punjab University/PUCIT'),
    (1, 4, 'International Islamic University'),
    (1, 5, 'Namal'),
    (2, 1, 'Other'),
    (2, 2, 'NTU'),
    (2, 3, 'NUST'),
    (2, 4, 'COMSATS'),
    (2, 5, 'Quaid-i-Azam University'),
    (3, 1, 'Other'),
    (3, 2, 'NCA'),
    (3, 3, 'ITU'),
    (3, 4, 'IBA'),
    (3, 5, 'NTU'),
    (4, 1, 'GIK'),
    (4, 2, 'PIEAS'),
    (4, 3, 'LUMS'),
    (4, 4, 'FAST-NUCES'),
    (4, 5, 'UET Taxila / Chakwal')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Avionics'),
    (1, 2, 'Textile'),
    (1, 3, 'Chemical'),
    (1, 4, 'Petroleum'),
    (1, 5, 'Biomedical'),
    (2, 1, 'Agricultural'),
    (2, 2, 'Mechatronics'),
    (2, 3, 'Avionics'),
    (2, 4, 'Architecture'),
    (2, 5, 'Mining'),
    (3, 1, 'Mechatronics'),
    (3, 2, 'Architectural'),
    (3, 3, 'Electrical'),
    (3, 4, 'Avionics'),
    (3, 5, 'Architecture'),
    (4, 1, 'Biomedical'),
    (4, 2, 'Mechatronics'),
    (4, 3, 'Other'),
    (4, 4, 'Chemical'),
    (4, 5, 'Mining')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Data Sciences'),
    (2, 'Artificial Intelligence'),
    (3, 'Other'),
    (4, 'Computer Science'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [46/100] NIMRA WARDAG (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-nimra-wardag-f13-pe-1313@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"NIMRA WARDAG"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'NIMRA WARDAG', 'Pre-Engineering', 'F13 PE', 'F13-PE-1313', 1024.0, 397.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Punjab University Engineering Programs'),
    (1, 2, 'International Islamic University'),
    (1, 3, 'NCA'),
    (1, 4, 'NUST'),
    (1, 5, 'NTU'),
    (2, 1, 'FAST-NUCES'),
    (2, 2, 'NUST'),
    (2, 3, 'UET Taxila / Chakwal'),
    (2, 4, 'Punjab University/PUCIT'),
    (2, 5, 'Other'),
    (3, 1, 'FAST-NUCES'),
    (3, 2, 'LSE'),
    (3, 3, 'IBA'),
    (3, 4, 'ITU'),
    (3, 5, 'UET Taxila / Chakwal'),
    (4, 1, 'IBA'),
    (4, 2, 'LSE'),
    (4, 3, 'NUST'),
    (4, 4, 'UET Taxila / Chakwal'),
    (4, 5, 'Other')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Mechanical'),
    (1, 2, 'Transportation'),
    (1, 3, 'Biomedical'),
    (1, 4, 'Civil'),
    (1, 5, 'Aerospace'),
    (2, 1, 'Architectural'),
    (2, 2, 'Mining'),
    (2, 3, 'Transportation'),
    (2, 4, 'Environmental'),
    (2, 5, 'Biomedical'),
    (3, 1, 'Mechanical'),
    (3, 2, 'Mechatronics'),
    (3, 3, 'Other'),
    (3, 4, 'Textile'),
    (3, 5, 'Architectural'),
    (4, 1, 'Transportation'),
    (4, 2, 'Aerospace'),
    (4, 3, 'Polymer'),
    (4, 4, 'Architectural'),
    (4, 5, 'Metallurgical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Artificial Intelligence'),
    (2, 'Data Sciences'),
    (3, 'Computer Science'),
    (4, 'Other'),
    (5, 'Hardware Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [47/100] MIRRAL WAHLA (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-mirral-wahla-f06-pe-615@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MIRRAL WAHLA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MIRRAL WAHLA', 'Pre-Engineering', 'F6 PE', 'F06-PE-615', 1105.0, 658.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'LSE'),
    (1, 2, 'Punjab University Engineering Programs'),
    (1, 3, 'IBA'),
    (1, 4, 'NTU'),
    (1, 5, 'ITU'),
    (2, 1, 'LSE'),
    (2, 2, 'FAST-NUCES'),
    (2, 3, 'Namal'),
    (2, 4, 'Punjab University/PUCIT'),
    (2, 5, 'NCA'),
    (3, 1, 'GIK'),
    (3, 2, 'Punjab University Engineering Programs'),
    (3, 3, 'PIFD'),
    (3, 4, 'FAST-NUCES'),
    (3, 5, 'International Islamic University'),
    (4, 1, 'NUST'),
    (4, 2, 'IST'),
    (4, 3, 'Air University'),
    (4, 4, 'IBA'),
    (4, 5, 'GIK')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'Metallurgical'),
    (1, 3, 'Industrial & Manufacturing'),
    (1, 4, 'Environmental'),
    (1, 5, 'Electrical'),
    (2, 1, 'Avionics'),
    (2, 2, 'Aeronautical'),
    (2, 3, 'Mechanical'),
    (2, 4, 'Electrical'),
    (2, 5, 'Petroleum'),
    (3, 1, 'Civil'),
    (3, 2, 'Textile'),
    (3, 3, 'Other'),
    (3, 4, 'Polymer'),
    (3, 5, 'Mining'),
    (4, 1, 'Industrial & Manufacturing'),
    (4, 2, 'Biomedical'),
    (4, 3, 'Textile'),
    (4, 4, 'Architecture'),
    (4, 5, 'Chemical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Science'),
    (2, 'Software Engineering'),
    (3, 'Cybersecurity'),
    (4, 'Artificial Intelligence'),
    (5, 'Computer Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [48/100] SUHAIMAH YOUSAF (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-suhaimah-yousaf-f13-pe-1316@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"SUHAIMAH YOUSAF"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'SUHAIMAH YOUSAF', 'Pre-Engineering', 'F13 PE', 'F13-PE-1316', 994.0, 488.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'UET Taxila / Chakwal'),
    (1, 2, 'NASTP'),
    (1, 3, 'ITU'),
    (1, 4, 'Other'),
    (1, 5, 'Punjab University/PUCIT'),
    (2, 1, 'NTU'),
    (2, 2, 'Punjab University Engineering Programs'),
    (2, 3, 'GIK'),
    (2, 4, 'UET Lahore'),
    (2, 5, 'COMSATS'),
    (3, 1, 'NASTP'),
    (3, 2, 'Punjab University/PUCIT'),
    (3, 3, 'IBA'),
    (3, 4, 'FAST-NUCES'),
    (3, 5, 'NCA'),
    (4, 1, 'UET Taxila / Chakwal'),
    (4, 2, 'Punjab University Engineering Programs'),
    (4, 3, 'Namal'),
    (4, 4, 'International Islamic University'),
    (4, 5, 'PIEAS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Biomedical'),
    (1, 2, 'Civil'),
    (1, 3, 'Mechanical'),
    (1, 4, 'Industrial & Manufacturing'),
    (1, 5, 'Avionics'),
    (2, 1, 'Mechanical'),
    (2, 2, 'Architectural'),
    (2, 3, 'Civil'),
    (2, 4, 'Biomedical'),
    (2, 5, 'Textile'),
    (3, 1, 'Other'),
    (3, 2, 'Polymer'),
    (3, 3, 'Chemical'),
    (3, 4, 'Petroleum'),
    (3, 5, 'Architecture'),
    (4, 1, 'Biomedical'),
    (4, 2, 'Polymer'),
    (4, 3, 'Avionics'),
    (4, 4, 'Agricultural'),
    (4, 5, 'Petroleum')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Computer Engineering'),
    (3, 'Cybersecurity'),
    (4, 'IT'),
    (5, 'Artificial Intelligence')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [49/100] MINAHAL FATIMA (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-minahal-fatima-f06-pe-618@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MINAHAL FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MINAHAL FATIMA', 'Pre-Engineering', 'F6 PE', 'F06-PE-618', 1093.0, 510.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Quaid-i-Azam University'),
    (1, 2, 'LUMS'),
    (1, 3, 'PIEAS'),
    (1, 4, 'International Islamic University'),
    (1, 5, 'LSE'),
    (2, 1, 'Bahria University'),
    (2, 2, 'LSE'),
    (2, 3, 'ITU'),
    (2, 4, 'Punjab University/PUCIT'),
    (2, 5, 'NUST'),
    (3, 1, 'ITU'),
    (3, 2, 'IBA'),
    (3, 3, 'UET Lahore'),
    (3, 4, 'NUST'),
    (3, 5, 'Punjab University/PUCIT'),
    (4, 1, 'UET Taxila / Chakwal'),
    (4, 2, 'NUST'),
    (4, 3, 'LSE'),
    (4, 4, 'Other'),
    (4, 5, 'International Islamic University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Aeronautical'),
    (1, 2, 'Polymer'),
    (1, 3, 'Mechatronics'),
    (1, 4, 'Civil'),
    (1, 5, 'Electrical'),
    (2, 1, 'Textile'),
    (2, 2, 'Petroleum'),
    (2, 3, 'Polymer'),
    (2, 4, 'Transportation'),
    (2, 5, 'Mechatronics'),
    (3, 1, 'Environmental'),
    (3, 2, 'Petroleum'),
    (3, 3, 'Civil'),
    (3, 4, 'Mechatronics'),
    (3, 5, 'Architectural'),
    (4, 1, 'Avionics'),
    (4, 2, 'Electronics'),
    (4, 3, 'Architectural'),
    (4, 4, 'Mechanical'),
    (4, 5, 'Transportation')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'IT'),
    (3, 'Hardware Engineering'),
    (4, 'Software Engineering'),
    (5, 'Data Sciences')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [50/100] DUR E SAMEEN (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-dur-e-sameen-f13-pe-1320@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"DUR E SAMEEN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'DUR E SAMEEN', 'Pre-Engineering', 'F13 PE', 'F13-PE-1320', 935.0, 415.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Bahria University'),
    (1, 2, 'UET Taxila / Chakwal'),
    (1, 3, 'PIFD'),
    (1, 4, 'COMSATS'),
    (1, 5, 'Quaid-i-Azam University'),
    (2, 1, 'COMSATS'),
    (2, 2, 'PIFD'),
    (2, 3, 'NUST'),
    (2, 4, 'Other'),
    (2, 5, 'NASTP'),
    (3, 1, 'ITU'),
    (3, 2, 'PIFD'),
    (3, 3, 'LUMS'),
    (3, 4, 'International Islamic University'),
    (3, 5, 'Punjab University/PUCIT'),
    (4, 1, 'NCA'),
    (4, 2, 'Other'),
    (4, 3, 'Punjab University/PUCIT'),
    (4, 4, 'LUMS'),
    (4, 5, 'PIFD')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Architectural'),
    (1, 2, 'Electrical'),
    (1, 3, 'Metallurgical'),
    (1, 4, 'Biomedical'),
    (1, 5, 'Agricultural'),
    (2, 1, 'Transportation'),
    (2, 2, 'Chemical'),
    (2, 3, 'Avionics'),
    (2, 4, 'Environmental'),
    (2, 5, 'Mechanical'),
    (3, 1, 'Architectural'),
    (3, 2, 'Mechatronics'),
    (3, 3, 'Textile'),
    (3, 4, 'Aerospace'),
    (3, 5, 'Mechanical'),
    (4, 1, 'Biomedical'),
    (4, 2, 'Civil'),
    (4, 3, 'Mining'),
    (4, 4, 'Agricultural'),
    (4, 5, 'Aerospace')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Computer Engineering'),
    (3, 'Artificial Intelligence'),
    (4, 'Data Sciences'),
    (5, 'Hardware Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [51/100] MAHRUKH SAEED (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-mahrukh-saeed-f06-pe-621@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MAHRUKH SAEED"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MAHRUKH SAEED', 'Pre-Engineering', 'F6 PE', 'F06-PE-621', 1082.0, 662.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'GIK'),
    (1, 2, 'Namal'),
    (1, 3, 'FAST-NUCES'),
    (1, 4, 'PIEAS'),
    (1, 5, 'NCA'),
    (2, 1, 'IST'),
    (2, 2, 'Punjab University/PUCIT'),
    (2, 3, 'COMSATS'),
    (2, 4, 'UET Lahore'),
    (2, 5, 'NUST'),
    (3, 1, 'IST'),
    (3, 2, 'IBA'),
    (3, 3, 'NUST'),
    (3, 4, 'LSE'),
    (3, 5, 'International Islamic University'),
    (4, 1, 'NCA'),
    (4, 2, 'FAST-NUCES'),
    (4, 3, 'Bahria University'),
    (4, 4, 'LSE'),
    (4, 5, 'GIK')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Chemical'),
    (1, 2, 'Biomedical'),
    (1, 3, 'Civil'),
    (1, 4, 'Mechanical'),
    (1, 5, 'Mining'),
    (2, 1, 'Electronics'),
    (2, 2, 'Transportation'),
    (2, 3, 'Polymer'),
    (2, 4, 'Chemical'),
    (2, 5, 'Architecture'),
    (3, 1, 'Electrical'),
    (3, 2, 'Mechatronics'),
    (3, 3, 'Aerospace'),
    (3, 4, 'Architecture'),
    (3, 5, 'Aeronautical'),
    (4, 1, 'Mining'),
    (4, 2, 'Mechanical'),
    (4, 3, 'Electronics'),
    (4, 4, 'Avionics'),
    (4, 5, 'Transportation')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'IT'),
    (3, 'Computer Engineering'),
    (4, 'Data Sciences'),
    (5, 'Artificial Intelligence')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [52/100] HAMNA IKRAM (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hamna-ikram-f13-pe-1323@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HAMNA IKRAM"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HAMNA IKRAM', 'Pre-Engineering', 'F13 PE', 'F13-PE-1323', 780.0, 325.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NTU'),
    (1, 2, 'Air University'),
    (1, 3, 'International Islamic University'),
    (1, 4, 'COMSATS'),
    (1, 5, 'PIFD'),
    (2, 1, 'COMSATS'),
    (2, 2, 'NASTP'),
    (2, 3, 'Punjab University Engineering Programs'),
    (2, 4, 'PIFD'),
    (2, 5, 'NCA'),
    (3, 1, 'Quaid-i-Azam University'),
    (3, 2, 'ITU'),
    (3, 3, 'NTU'),
    (3, 4, 'Namal'),
    (3, 5, 'GIK'),
    (4, 1, 'LUMS'),
    (4, 2, 'LSE'),
    (4, 3, 'IST'),
    (4, 4, 'NTU'),
    (4, 5, 'Punjab University Engineering Programs')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Aeronautical'),
    (1, 2, 'Petroleum'),
    (1, 3, 'Avionics'),
    (1, 4, 'Mining'),
    (1, 5, 'Architectural'),
    (2, 1, 'Textile'),
    (2, 2, 'Chemical'),
    (2, 3, 'Electronics'),
    (2, 4, 'Architectural'),
    (2, 5, 'Mechatronics'),
    (3, 1, 'Mining'),
    (3, 2, 'Telecommunication'),
    (3, 3, 'Chemical'),
    (3, 4, 'Transportation'),
    (3, 5, 'Civil'),
    (4, 1, 'Architecture'),
    (4, 2, 'Petroleum'),
    (4, 3, 'Architectural'),
    (4, 4, 'Mechatronics'),
    (4, 5, 'Aerospace')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Science'),
    (2, 'Artificial Intelligence'),
    (3, 'Other'),
    (4, 'Hardware Engineering'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [53/100] FARAH FATIMA (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-farah-fatima-f06-pe-624@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FARAH FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FARAH FATIMA', 'Pre-Engineering', 'F6 PE', 'F06-PE-624', 1072.0, 500.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'International Islamic University'),
    (1, 2, 'UET Lahore'),
    (1, 3, 'LUMS'),
    (1, 4, 'FAST-NUCES'),
    (1, 5, 'LSE'),
    (2, 1, 'Other'),
    (2, 2, 'Bahria University'),
    (2, 3, 'PIEAS'),
    (2, 4, 'Punjab University/PUCIT'),
    (2, 5, 'UET Lahore'),
    (3, 1, 'IST'),
    (3, 2, 'COMSATS'),
    (3, 3, 'GIK'),
    (3, 4, 'Quaid-i-Azam University'),
    (3, 5, 'Other'),
    (4, 1, 'Punjab University Engineering Programs'),
    (4, 2, 'FAST-NUCES'),
    (4, 3, 'ITU'),
    (4, 4, 'LSE'),
    (4, 5, 'UET Taxila / Chakwal')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Polymer'),
    (1, 2, 'Avionics'),
    (1, 3, 'Chemical'),
    (1, 4, 'Textile'),
    (1, 5, 'Mining'),
    (2, 1, 'Civil'),
    (2, 2, 'Mechanical'),
    (2, 3, 'Architecture'),
    (2, 4, 'Transportation'),
    (2, 5, 'Biomedical'),
    (3, 1, 'Transportation'),
    (3, 2, 'Mechanical'),
    (3, 3, 'Polymer'),
    (3, 4, 'Telecommunication'),
    (3, 5, 'Agricultural'),
    (4, 1, 'Mechatronics'),
    (4, 2, 'Aeronautical'),
    (4, 3, 'Architecture'),
    (4, 4, 'Mechanical'),
    (4, 5, 'Metallurgical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Computer Engineering'),
    (3, 'Computer Science'),
    (4, 'Software Engineering'),
    (5, 'Hardware Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [54/100] ALVEENA AFZAL (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-alveena-afzal-f13-pe-1326@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ALVEENA AFZAL"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ALVEENA AFZAL', 'Pre-Engineering', 'F13 PE', 'F13-PE-1326', 1122.0, 640.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NCA'),
    (1, 2, 'GIK'),
    (1, 3, 'UET Taxila / Chakwal'),
    (1, 4, 'PIEAS'),
    (1, 5, 'Namal'),
    (2, 1, 'NUST'),
    (2, 2, 'International Islamic University'),
    (2, 3, 'ITU'),
    (2, 4, 'NTU'),
    (2, 5, 'Air University'),
    (3, 1, 'Namal'),
    (3, 2, 'NASTP'),
    (3, 3, 'Bahria University'),
    (3, 4, 'PIEAS'),
    (3, 5, 'UET Taxila / Chakwal'),
    (4, 1, 'Air University'),
    (4, 2, 'International Islamic University'),
    (4, 3, 'NCA'),
    (4, 4, 'Other'),
    (4, 5, 'ITU')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Chemical'),
    (1, 2, 'Metallurgical'),
    (1, 3, 'Avionics'),
    (1, 4, 'Industrial & Manufacturing'),
    (1, 5, 'Polymer'),
    (2, 1, 'Architecture'),
    (2, 2, 'Industrial & Manufacturing'),
    (2, 3, 'Telecommunication'),
    (2, 4, 'Textile'),
    (2, 5, 'Architectural'),
    (3, 1, 'Electronics'),
    (3, 2, 'Industrial & Manufacturing'),
    (3, 3, 'Avionics'),
    (3, 4, 'Telecommunication'),
    (3, 5, 'Petroleum'),
    (4, 1, 'Metallurgical'),
    (4, 2, 'Transportation'),
    (4, 3, 'Mechatronics'),
    (4, 4, 'Architectural'),
    (4, 5, 'Chemical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'IT'),
    (3, 'Artificial Intelligence'),
    (4, 'Data Sciences'),
    (5, 'Other')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [55/100] SOHA SARDAR (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-soha-sardar-f06-pe-627@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"SOHA SARDAR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'SOHA SARDAR', 'Pre-Engineering', 'F6 PE', 'F06-PE-627', 1010.0, 764.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'UET Lahore'),
    (1, 2, 'COMSATS'),
    (1, 3, 'LSE'),
    (1, 4, 'International Islamic University'),
    (1, 5, 'PIFD'),
    (2, 1, 'PIFD'),
    (2, 2, 'Namal'),
    (2, 3, 'ITU'),
    (2, 4, 'NUST'),
    (2, 5, 'UET Lahore'),
    (3, 1, 'IST'),
    (3, 2, 'Punjab University Engineering Programs'),
    (3, 3, 'LSE'),
    (3, 4, 'International Islamic University'),
    (3, 5, 'NUST'),
    (4, 1, 'LUMS'),
    (4, 2, 'NUST'),
    (4, 3, 'NASTP'),
    (4, 4, 'ITU'),
    (4, 5, 'COMSATS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Industrial & Manufacturing'),
    (1, 2, 'Mining'),
    (1, 3, 'Transportation'),
    (1, 4, 'Electronics'),
    (1, 5, 'Architecture'),
    (2, 1, 'Transportation'),
    (2, 2, 'Metallurgical'),
    (2, 3, 'Mechanical'),
    (2, 4, 'Polymer'),
    (2, 5, 'Petroleum'),
    (3, 1, 'Chemical'),
    (3, 2, 'Avionics'),
    (3, 3, 'Mechatronics'),
    (3, 4, 'Environmental'),
    (3, 5, 'Telecommunication'),
    (4, 1, 'Industrial & Manufacturing'),
    (4, 2, 'Environmental'),
    (4, 3, 'Aeronautical'),
    (4, 4, 'Electronics'),
    (4, 5, 'Agricultural')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Artificial Intelligence'),
    (2, 'Computer Science'),
    (3, 'Other'),
    (4, 'Data Sciences'),
    (5, 'Computer Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [56/100] HAREEM SHEHZAD (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hareem-shehzad-f06-pe-630@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HAREEM SHEHZAD"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HAREEM SHEHZAD', 'Pre-Engineering', 'F6 PE', 'F06-PE-630', 989.0, 444.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NCA'),
    (1, 2, 'UET Taxila / Chakwal'),
    (1, 3, 'LUMS'),
    (1, 4, 'NUST'),
    (1, 5, 'International Islamic University'),
    (2, 1, 'Air University'),
    (2, 2, 'ITU'),
    (2, 3, 'LSE'),
    (2, 4, 'International Islamic University'),
    (2, 5, 'NASTP'),
    (3, 1, 'NTU'),
    (3, 2, 'LSE'),
    (3, 3, 'Namal'),
    (3, 4, 'Other'),
    (3, 5, 'IST'),
    (4, 1, 'Punjab University Engineering Programs'),
    (4, 2, 'GIK'),
    (4, 3, 'LUMS'),
    (4, 4, 'NUST'),
    (4, 5, 'Air University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Civil'),
    (1, 2, 'Telecommunication'),
    (1, 3, 'Transportation'),
    (1, 4, 'Aerospace'),
    (1, 5, 'Petroleum'),
    (2, 1, 'Biomedical'),
    (2, 2, 'Electronics'),
    (2, 3, 'Environmental'),
    (2, 4, 'Architecture'),
    (2, 5, 'Architectural'),
    (3, 1, 'Transportation'),
    (3, 2, 'Avionics'),
    (3, 3, 'Textile'),
    (3, 4, 'Chemical'),
    (3, 5, 'Architecture'),
    (4, 1, 'Electrical'),
    (4, 2, 'Petroleum'),
    (4, 3, 'Other'),
    (4, 4, 'Architecture'),
    (4, 5, 'Polymer')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Engineering'),
    (2, 'Other'),
    (3, 'Artificial Intelligence'),
    (4, 'Data Sciences'),
    (5, 'IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [57/100] ALINA YASMEEN (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-alina-yasmeen-f06-pe-633@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ALINA YASMEEN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ALINA YASMEEN', 'Pre-Engineering', 'F6 PE', 'F06-PE-633', 894.0, 336.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'IST'),
    (1, 3, 'Bahria University'),
    (1, 4, 'Air University'),
    (1, 5, 'LUMS'),
    (2, 1, 'NCA'),
    (2, 2, 'PIFD'),
    (2, 3, 'Other'),
    (2, 4, 'NTU'),
    (2, 5, 'FAST-NUCES'),
    (3, 1, 'Other'),
    (3, 2, 'International Islamic University'),
    (3, 3, 'NTU'),
    (3, 4, 'GIK'),
    (3, 5, 'Punjab University Engineering Programs'),
    (4, 1, 'PIEAS'),
    (4, 2, 'UET Taxila / Chakwal'),
    (4, 3, 'Punjab University Engineering Programs'),
    (4, 4, 'International Islamic University'),
    (4, 5, 'NUST')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Electrical'),
    (1, 2, 'Mining'),
    (1, 3, 'Chemical'),
    (1, 4, 'Petroleum'),
    (1, 5, 'Mechatronics'),
    (2, 1, 'Civil'),
    (2, 2, 'Electrical'),
    (2, 3, 'Avionics'),
    (2, 4, 'Aerospace'),
    (2, 5, 'Agricultural'),
    (3, 1, 'Architectural'),
    (3, 2, 'Architecture'),
    (3, 3, 'Biomedical'),
    (3, 4, 'Telecommunication'),
    (3, 5, 'Avionics'),
    (4, 1, 'Aeronautical'),
    (4, 2, 'Telecommunication'),
    (4, 3, 'Biomedical'),
    (4, 4, 'Avionics'),
    (4, 5, 'Chemical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Software Engineering'),
    (3, 'Computer Science'),
    (4, 'IT'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [58/100] HAFSA AZAM (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hafsa-azam-f06-pe-636@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HAFSA AZAM"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HAFSA AZAM', 'Pre-Engineering', 'F6 PE', 'F06-PE-636', 856.0, 469.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'GIK'),
    (1, 2, 'Other'),
    (1, 3, 'IBA'),
    (1, 4, 'Punjab University/PUCIT'),
    (1, 5, 'NCA'),
    (2, 1, 'IBA'),
    (2, 2, 'LSE'),
    (2, 3, 'Punjab University Engineering Programs'),
    (2, 4, 'NCA'),
    (2, 5, 'International Islamic University'),
    (3, 1, 'Bahria University'),
    (3, 2, 'Quaid-i-Azam University'),
    (3, 3, 'Air University'),
    (3, 4, 'IST'),
    (3, 5, 'Namal'),
    (4, 1, 'Bahria University'),
    (4, 2, 'LUMS'),
    (4, 3, 'PIFD'),
    (4, 4, 'Other'),
    (4, 5, 'Punjab University Engineering Programs')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Civil'),
    (1, 2, 'Metallurgical'),
    (1, 3, 'Other'),
    (1, 4, 'Industrial & Manufacturing'),
    (1, 5, 'Mechatronics'),
    (2, 1, 'Industrial & Manufacturing'),
    (2, 2, 'Aeronautical'),
    (2, 3, 'Aerospace'),
    (2, 4, 'Agricultural'),
    (2, 5, 'Biomedical'),
    (3, 1, 'Agricultural'),
    (3, 2, 'Telecommunication'),
    (3, 3, 'Industrial & Manufacturing'),
    (3, 4, 'Environmental'),
    (3, 5, 'Aeronautical'),
    (4, 1, 'Architectural'),
    (4, 2, 'Mechanical'),
    (4, 3, 'Telecommunication'),
    (4, 4, 'Electrical'),
    (4, 5, 'Chemical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Software Engineering'),
    (2, 'Hardware Engineering'),
    (3, 'Cybersecurity'),
    (4, 'Artificial Intelligence'),
    (5, 'Computer Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [59/100] FIZA CHISHTI (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-fiza-chishti-f06-pe-640@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FIZA CHISHTI"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FIZA CHISHTI', 'Pre-Engineering', 'F6 PE', 'F06-PE-640', 1127.0, 581.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NASTP'),
    (1, 2, 'ITU'),
    (1, 3, 'Punjab University/PUCIT'),
    (1, 4, 'Air University'),
    (1, 5, 'Quaid-i-Azam University'),
    (2, 1, 'FAST-NUCES'),
    (2, 2, 'Bahria University'),
    (2, 3, 'NCA'),
    (2, 4, 'PIEAS'),
    (2, 5, 'Punjab University Engineering Programs'),
    (3, 1, 'Punjab University/PUCIT'),
    (3, 2, 'PIEAS'),
    (3, 3, 'NUST'),
    (3, 4, 'International Islamic University'),
    (3, 5, 'FAST-NUCES'),
    (4, 1, 'International Islamic University'),
    (4, 2, 'COMSATS'),
    (4, 3, 'IST'),
    (4, 4, 'PIEAS'),
    (4, 5, 'UET Lahore')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Electronics'),
    (1, 2, 'Environmental'),
    (1, 3, 'Architectural'),
    (1, 4, 'Mining'),
    (1, 5, 'Avionics'),
    (2, 1, 'Electronics'),
    (2, 2, 'Mechanical'),
    (2, 3, 'Chemical'),
    (2, 4, 'Architecture'),
    (2, 5, 'Mechatronics'),
    (3, 1, 'Electrical'),
    (3, 2, 'Civil'),
    (3, 3, 'Avionics'),
    (3, 4, 'Chemical'),
    (3, 5, 'Transportation'),
    (4, 1, 'Architecture'),
    (4, 2, 'Other'),
    (4, 3, 'Electrical'),
    (4, 4, 'Mechatronics'),
    (4, 5, 'Aeronautical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Science'),
    (2, 'Computer Engineering'),
    (3, 'Artificial Intelligence'),
    (4, 'Other'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [60/100] FATIMA ABID (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-fatima-abid-f06-pe-643@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FATIMA ABID"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FATIMA ABID', 'Pre-Engineering', 'F6 PE', 'F06-PE-643', 1068.0, 607.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'PIEAS'),
    (1, 2, 'ITU'),
    (1, 3, 'IST'),
    (1, 4, 'Bahria University'),
    (1, 5, 'NUST'),
    (2, 1, 'Air University'),
    (2, 2, 'NASTP'),
    (2, 3, 'Punjab University/PUCIT'),
    (2, 4, 'Bahria University'),
    (2, 5, 'FAST-NUCES'),
    (3, 1, 'NASTP'),
    (3, 2, 'COMSATS'),
    (3, 3, 'GIK'),
    (3, 4, 'PIFD'),
    (3, 5, 'LUMS'),
    (4, 1, 'Namal'),
    (4, 2, 'Punjab University/PUCIT'),
    (4, 3, 'COMSATS'),
    (4, 4, 'NUST'),
    (4, 5, 'LUMS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Civil'),
    (1, 2, 'Aeronautical'),
    (1, 3, 'Architectural'),
    (1, 4, 'Environmental'),
    (1, 5, 'Metallurgical'),
    (2, 1, 'Metallurgical'),
    (2, 2, 'Biomedical'),
    (2, 3, 'Industrial & Manufacturing'),
    (2, 4, 'Electrical'),
    (2, 5, 'Transportation'),
    (3, 1, 'Industrial & Manufacturing'),
    (3, 2, 'Environmental'),
    (3, 3, 'Mechatronics'),
    (3, 4, 'Other'),
    (3, 5, 'Transportation'),
    (4, 1, 'Metallurgical'),
    (4, 2, 'Avionics'),
    (4, 3, 'Telecommunication'),
    (4, 4, 'Textile'),
    (4, 5, 'Environmental')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Science'),
    (2, 'Cybersecurity'),
    (3, 'Other'),
    (4, 'Hardware Engineering'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [61/100] HAFSA SHAHID (F10 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hafsa-shahid-f10-ics-1051@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HAFSA SHAHID"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HAFSA SHAHID', 'ICS', 'F10 ICS', 'F10-ICS-1051', 1156.0, 799.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'PIEAS'),
    (1, 2, 'NCA'),
    (1, 3, 'Other'),
    (1, 4, 'FAST-NUCES'),
    (1, 5, 'PIFD'),
    (2, 1, 'International Islamic University'),
    (2, 2, 'LUMS'),
    (2, 3, 'ITU'),
    (2, 4, 'Punjab University/PUCIT'),
    (2, 5, 'COMSATS'),
    (3, 1, 'UET Taxila / Chakwal'),
    (3, 2, 'PIFD'),
    (3, 3, 'Air University'),
    (3, 4, 'Namal'),
    (3, 5, 'GIK'),
    (4, 1, 'NCA'),
    (4, 2, 'International Islamic University'),
    (4, 3, 'Punjab University Engineering Programs'),
    (4, 4, 'NTU'),
    (4, 5, 'UET Lahore')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Artificial Intelligence'),
    (1, 2, 'Data Sciences'),
    (1, 3, 'Computer Science'),
    (1, 4, 'Hardware Engineering'),
    (1, 5, 'Computer Engineering'),
    (2, 1, 'Data Sciences'),
    (2, 2, 'Artificial Intelligence'),
    (2, 3, 'Cybersecurity'),
    (2, 4, 'Software Engineering'),
    (2, 5, 'IT'),
    (3, 1, 'IT'),
    (3, 2, 'Software Engineering'),
    (3, 3, 'Cybersecurity'),
    (3, 4, 'Computer Engineering'),
    (3, 5, 'Artificial Intelligence'),
    (4, 1, 'Data Sciences'),
    (4, 2, 'IT'),
    (4, 3, 'Computer Science'),
    (4, 4, 'Artificial Intelligence'),
    (4, 5, 'Cybersecurity')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Data Sciences'),
    (2, 'Computer Engineering'),
    (3, 'Artificial Intelligence'),
    (4, 'IT'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [62/100] BAREERA SHAFIQ (F14 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-bareera-shafiq-f14-ics-1401@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"BAREERA SHAFIQ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'BAREERA SHAFIQ', 'ICS', 'F14 ICS', 'F14-ICS-1401', 1022.0, 532.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'UET Lahore'),
    (1, 2, 'Other'),
    (1, 3, 'Punjab University Engineering Programs'),
    (1, 4, 'IBA'),
    (1, 5, 'LSE'),
    (2, 1, 'Namal'),
    (2, 2, 'ITU'),
    (2, 3, 'GIK'),
    (2, 4, 'Punjab University Engineering Programs'),
    (2, 5, 'IBA'),
    (3, 1, 'Punjab University/PUCIT'),
    (3, 2, 'UET Taxila / Chakwal'),
    (3, 3, 'Other'),
    (3, 4, 'PIEAS'),
    (3, 5, 'GIK'),
    (4, 1, 'Quaid-i-Azam University'),
    (4, 2, 'PIEAS'),
    (4, 3, 'Punjab University/PUCIT'),
    (4, 4, 'NCA'),
    (4, 5, 'UET Lahore')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'Computer Science'),
    (1, 3, 'IT'),
    (1, 4, 'Software Engineering'),
    (1, 5, 'Cybersecurity'),
    (2, 1, 'Other'),
    (2, 2, 'IT'),
    (2, 3, 'Cybersecurity'),
    (2, 4, 'Hardware Engineering'),
    (2, 5, 'Software Engineering'),
    (3, 1, 'Artificial Intelligence'),
    (3, 2, 'IT'),
    (3, 3, 'Hardware Engineering'),
    (3, 4, 'Cybersecurity'),
    (3, 5, 'Data Sciences'),
    (4, 1, 'Hardware Engineering'),
    (4, 2, 'IT'),
    (4, 3, 'Data Sciences'),
    (4, 4, 'Other'),
    (4, 5, 'Computer Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Hardware Engineering'),
    (3, 'IT'),
    (4, 'Cybersecurity'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [63/100] FIZZA AHMAD (F9 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-fizza-ahmad-f09-ics-901@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FIZZA AHMAD"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FIZZA AHMAD', 'ICS', 'F9 ICS', 'F09-ICS-901', 1163.0, 683.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'UET Taxila / Chakwal'),
    (1, 2, 'LSE'),
    (1, 3, 'Other'),
    (1, 4, 'NCA'),
    (1, 5, 'LUMS'),
    (2, 1, 'Other'),
    (2, 2, 'Punjab University Engineering Programs'),
    (2, 3, 'PIFD'),
    (2, 4, 'Bahria University'),
    (2, 5, 'NASTP'),
    (3, 1, 'NASTP'),
    (3, 2, 'Other'),
    (3, 3, 'International Islamic University'),
    (3, 4, 'PIFD'),
    (3, 5, 'Punjab University Engineering Programs'),
    (4, 1, 'Quaid-i-Azam University'),
    (4, 2, 'Other'),
    (4, 3, 'International Islamic University'),
    (4, 4, 'Bahria University'),
    (4, 5, 'NASTP')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'IT'),
    (1, 2, 'Software Engineering'),
    (1, 3, 'Artificial Intelligence'),
    (1, 4, 'Other'),
    (1, 5, 'Hardware Engineering'),
    (2, 1, 'Software Engineering'),
    (2, 2, 'Hardware Engineering'),
    (2, 3, 'Computer Science'),
    (2, 4, 'Artificial Intelligence'),
    (2, 5, 'Cybersecurity'),
    (3, 1, 'Software Engineering'),
    (3, 2, 'Hardware Engineering'),
    (3, 3, 'Data Sciences'),
    (3, 4, 'Cybersecurity'),
    (3, 5, 'Computer Science'),
    (4, 1, 'Computer Science'),
    (4, 2, 'Cybersecurity'),
    (4, 3, 'Data Sciences'),
    (4, 4, 'Hardware Engineering'),
    (4, 5, 'Computer Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Software Engineering'),
    (3, 'Hardware Engineering'),
    (4, 'Computer Science'),
    (5, 'Computer Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [64/100] ANAM SAJID (F13 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-anam-sajid-f13-ics-1351@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ANAM SAJID"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ANAM SAJID', 'ICS', 'F13 ICS', 'F13-ICS-1351', 1146.0, 537.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NCA'),
    (1, 2, 'IST'),
    (1, 3, 'PIEAS'),
    (1, 4, 'NUST'),
    (1, 5, 'UET Taxila / Chakwal'),
    (2, 1, 'Air University'),
    (2, 2, 'Punjab University/PUCIT'),
    (2, 3, 'GIK'),
    (2, 4, 'Bahria University'),
    (2, 5, 'Namal'),
    (3, 1, 'ITU'),
    (3, 2, 'PIEAS'),
    (3, 3, 'NASTP'),
    (3, 4, 'NTU'),
    (3, 5, 'Air University'),
    (4, 1, 'Punjab University/PUCIT'),
    (4, 2, 'Bahria University'),
    (4, 3, 'IST'),
    (4, 4, 'Namal'),
    (4, 5, 'LUMS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Hardware Engineering'),
    (1, 2, 'IT'),
    (1, 3, 'Artificial Intelligence'),
    (1, 4, 'Computer Science'),
    (1, 5, 'Other'),
    (2, 1, 'Cybersecurity'),
    (2, 2, 'Artificial Intelligence'),
    (2, 3, 'IT'),
    (2, 4, 'Data Sciences'),
    (2, 5, 'Computer Science'),
    (3, 1, 'Cybersecurity'),
    (3, 2, 'Hardware Engineering'),
    (3, 3, 'Other'),
    (3, 4, 'Data Sciences'),
    (3, 5, 'Computer Engineering'),
    (4, 1, 'Software Engineering'),
    (4, 2, 'Cybersecurity'),
    (4, 3, 'Hardware Engineering'),
    (4, 4, 'Data Sciences'),
    (4, 5, 'Computer Science')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'IT'),
    (3, 'Artificial Intelligence'),
    (4, 'Data Sciences'),
    (5, 'Computer Science')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [65/100] DARAKHSHAN SHAHID (F8 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-darakhshan-shahid-f08-ics-801@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"DARAKHSHAN SHAHID"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'DARAKHSHAN SHAHID', 'ICS', 'F8 ICS', 'F08-ICS-801', 1050.0, 596.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Punjab University Engineering Programs'),
    (1, 2, 'COMSATS'),
    (1, 3, 'Other'),
    (1, 4, 'NCA'),
    (1, 5, 'Namal'),
    (2, 1, 'Punjab University Engineering Programs'),
    (2, 2, 'NCA'),
    (2, 3, 'NTU'),
    (2, 4, 'Punjab University/PUCIT'),
    (2, 5, 'GIK'),
    (3, 1, 'UET Lahore'),
    (3, 2, 'FAST-NUCES'),
    (3, 3, 'International Islamic University'),
    (3, 4, 'Punjab University/PUCIT'),
    (3, 5, 'IST'),
    (4, 1, 'International Islamic University'),
    (4, 2, 'Air University'),
    (4, 3, 'Other'),
    (4, 4, 'Punjab University Engineering Programs'),
    (4, 5, 'UET Lahore')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Artificial Intelligence'),
    (1, 2, 'Other'),
    (1, 3, 'Hardware Engineering'),
    (1, 4, 'Data Sciences'),
    (1, 5, 'Cybersecurity'),
    (2, 1, 'Hardware Engineering'),
    (2, 2, 'IT'),
    (2, 3, 'Other'),
    (2, 4, 'Software Engineering'),
    (2, 5, 'Computer Science'),
    (3, 1, 'Artificial Intelligence'),
    (3, 2, 'Computer Science'),
    (3, 3, 'IT'),
    (3, 4, 'Cybersecurity'),
    (3, 5, 'Hardware Engineering'),
    (4, 1, 'Cybersecurity'),
    (4, 2, 'Computer Science'),
    (4, 3, 'Data Sciences'),
    (4, 4, 'Other'),
    (4, 5, 'Hardware Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'Artificial Intelligence'),
    (3, 'Software Engineering'),
    (4, 'IT'),
    (5, 'Computer Science')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [66/100] UMEROMAN RANA (F15 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-umeroman-rana-f15-ics-1501@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"UMEROMAN RANA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'UMEROMAN RANA', 'ICS', 'F15 ICS', 'F15-ICS-1501', 972.0, 416.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'IST'),
    (1, 2, 'PIFD'),
    (1, 3, 'LSE'),
    (1, 4, 'International Islamic University'),
    (1, 5, 'FAST-NUCES'),
    (2, 1, 'Quaid-i-Azam University'),
    (2, 2, 'ITU'),
    (2, 3, 'UET Lahore'),
    (2, 4, 'COMSATS'),
    (2, 5, 'NCA'),
    (3, 1, 'NUST'),
    (3, 2, 'FAST-NUCES'),
    (3, 3, 'NASTP'),
    (3, 4, 'IBA'),
    (3, 5, 'UET Lahore'),
    (4, 1, 'Namal'),
    (4, 2, 'ITU'),
    (4, 3, 'International Islamic University'),
    (4, 4, 'NASTP'),
    (4, 5, 'LUMS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Artificial Intelligence'),
    (1, 2, 'Cybersecurity'),
    (1, 3, 'Hardware Engineering'),
    (1, 4, 'IT'),
    (1, 5, 'Software Engineering'),
    (2, 1, 'IT'),
    (2, 2, 'Data Sciences'),
    (2, 3, 'Other'),
    (2, 4, 'Computer Engineering'),
    (2, 5, 'Cybersecurity'),
    (3, 1, 'Cybersecurity'),
    (3, 2, 'Software Engineering'),
    (3, 3, 'Hardware Engineering'),
    (3, 4, 'Artificial Intelligence'),
    (3, 5, 'Computer Engineering'),
    (4, 1, 'Data Sciences'),
    (4, 2, 'Computer Science'),
    (4, 3, 'Cybersecurity'),
    (4, 4, 'Artificial Intelligence'),
    (4, 5, 'IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Artificial Intelligence'),
    (2, 'Hardware Engineering'),
    (3, 'Other'),
    (4, 'IT'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [67/100] HAFIZA SARA MURTAZA (F16 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hafiza-sara-murtaza-f16-ics-1651@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HAFIZA SARA MURTAZA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HAFIZA SARA MURTAZA', 'ICS', 'F16 ICS', 'F16-ICS-1651', 928.0, 489.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Namal'),
    (1, 2, 'FAST-NUCES'),
    (1, 3, 'Other'),
    (1, 4, 'NTU'),
    (1, 5, 'Quaid-i-Azam University'),
    (2, 1, 'PIEAS'),
    (2, 2, 'Air University'),
    (2, 3, 'UET Taxila / Chakwal'),
    (2, 4, 'PIFD'),
    (2, 5, 'Punjab University Engineering Programs'),
    (3, 1, 'UET Lahore'),
    (3, 2, 'IST'),
    (3, 3, 'Air University'),
    (3, 4, 'NUST'),
    (3, 5, 'NTU'),
    (4, 1, 'UET Lahore'),
    (4, 2, 'Bahria University'),
    (4, 3, 'IST'),
    (4, 4, 'Punjab University Engineering Programs'),
    (4, 5, 'GIK')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Computer Science'),
    (1, 2, 'Hardware Engineering'),
    (1, 3, 'Other'),
    (1, 4, 'Artificial Intelligence'),
    (1, 5, 'IT'),
    (2, 1, 'Software Engineering'),
    (2, 2, 'Computer Engineering'),
    (2, 3, 'Other'),
    (2, 4, 'Data Sciences'),
    (2, 5, 'Artificial Intelligence'),
    (3, 1, 'IT'),
    (3, 2, 'Data Sciences'),
    (3, 3, 'Other'),
    (3, 4, 'Computer Engineering'),
    (3, 5, 'Artificial Intelligence'),
    (4, 1, 'Cybersecurity'),
    (4, 2, 'IT'),
    (4, 3, 'Software Engineering'),
    (4, 4, 'Artificial Intelligence'),
    (4, 5, 'Other')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Engineering'),
    (2, 'Software Engineering'),
    (3, 'Other'),
    (4, 'Hardware Engineering'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [68/100] SARA REHAN (F7 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-sara-rehan-f07-ics-701@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"SARA REHAN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'SARA REHAN', 'ICS', 'F7 ICS', 'F07-ICS-701', 1182.0, 790.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'UET Lahore'),
    (1, 2, 'NUST'),
    (1, 3, 'Punjab University/PUCIT'),
    (1, 4, 'Bahria University'),
    (1, 5, 'PIFD'),
    (2, 1, 'International Islamic University'),
    (2, 2, 'UET Lahore'),
    (2, 3, 'IBA'),
    (2, 4, 'PIEAS'),
    (2, 5, 'Quaid-i-Azam University'),
    (3, 1, 'ITU'),
    (3, 2, 'IBA'),
    (3, 3, 'IST'),
    (3, 4, 'Namal'),
    (3, 5, 'Air University'),
    (4, 1, 'Punjab University/PUCIT'),
    (4, 2, 'COMSATS'),
    (4, 3, 'PIFD'),
    (4, 4, 'IBA'),
    (4, 5, 'UET Taxila / Chakwal')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'Computer Science'),
    (1, 3, 'Computer Engineering'),
    (1, 4, 'IT'),
    (1, 5, 'Hardware Engineering'),
    (2, 1, 'Data Sciences'),
    (2, 2, 'Software Engineering'),
    (2, 3, 'Cybersecurity'),
    (2, 4, 'Hardware Engineering'),
    (2, 5, 'IT'),
    (3, 1, 'Cybersecurity'),
    (3, 2, 'Other'),
    (3, 3, 'Artificial Intelligence'),
    (3, 4, 'Computer Science'),
    (3, 5, 'Computer Engineering'),
    (4, 1, 'Artificial Intelligence'),
    (4, 2, 'Computer Science'),
    (4, 3, 'Data Sciences'),
    (4, 4, 'Software Engineering'),
    (4, 5, 'Cybersecurity')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Artificial Intelligence'),
    (2, 'Computer Engineering'),
    (3, 'Software Engineering'),
    (4, 'Hardware Engineering'),
    (5, 'Other')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [69/100] MAHAM ARSHAD (F10 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-maham-arshad-f10-ics-1054@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MAHAM ARSHAD"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MAHAM ARSHAD', 'ICS', 'F10 ICS', 'F10-ICS-1054', 1085.0, 657.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'Air University'),
    (1, 3, 'NCA'),
    (1, 4, 'NASTP'),
    (1, 5, 'NUST'),
    (2, 1, 'NCA'),
    (2, 2, 'COMSATS'),
    (2, 3, 'PIEAS'),
    (2, 4, 'LUMS'),
    (2, 5, 'NUST'),
    (3, 1, 'Punjab University/PUCIT'),
    (3, 2, 'IST'),
    (3, 3, 'LSE'),
    (3, 4, 'Quaid-i-Azam University'),
    (3, 5, 'NUST'),
    (4, 1, 'Namal'),
    (4, 2, 'Air University'),
    (4, 3, 'LSE'),
    (4, 4, 'NCA'),
    (4, 5, 'UET Lahore')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'Computer Science'),
    (1, 3, 'Cybersecurity'),
    (1, 4, 'IT'),
    (1, 5, 'Artificial Intelligence'),
    (2, 1, 'Artificial Intelligence'),
    (2, 2, 'Data Sciences'),
    (2, 3, 'Hardware Engineering'),
    (2, 4, 'IT'),
    (2, 5, 'Software Engineering'),
    (3, 1, 'Software Engineering'),
    (3, 2, 'Artificial Intelligence'),
    (3, 3, 'Computer Engineering'),
    (3, 4, 'Data Sciences'),
    (3, 5, 'Hardware Engineering'),
    (4, 1, 'Computer Engineering'),
    (4, 2, 'Artificial Intelligence'),
    (4, 3, 'Other'),
    (4, 4, 'IT'),
    (4, 5, 'Data Sciences')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Computer Engineering'),
    (3, 'Cybersecurity'),
    (4, 'Computer Science'),
    (5, 'Hardware Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [70/100] EEMAN FATIMA (F14 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-eeman-fatima-f14-ics-1407@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"EEMAN FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'EEMAN FATIMA', 'ICS', 'F14 ICS', 'F14-ICS-1407', 1013.0, 471.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'LUMS'),
    (1, 2, 'PIFD'),
    (1, 3, 'NASTP'),
    (1, 4, 'International Islamic University'),
    (1, 5, 'NUST'),
    (2, 1, 'IST'),
    (2, 2, 'NASTP'),
    (2, 3, 'Namal'),
    (2, 4, 'NUST'),
    (2, 5, 'PIEAS'),
    (3, 1, 'PIFD'),
    (3, 2, 'NASTP'),
    (3, 3, 'Bahria University'),
    (3, 4, 'NCA'),
    (3, 5, 'NTU'),
    (4, 1, 'FAST-NUCES'),
    (4, 2, 'LUMS'),
    (4, 3, 'Quaid-i-Azam University'),
    (4, 4, 'NCA'),
    (4, 5, 'LSE')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Computer Engineering'),
    (1, 2, 'Hardware Engineering'),
    (1, 3, 'Computer Science'),
    (1, 4, 'Artificial Intelligence'),
    (1, 5, 'Data Sciences'),
    (2, 1, 'IT'),
    (2, 2, 'Computer Engineering'),
    (2, 3, 'Artificial Intelligence'),
    (2, 4, 'Data Sciences'),
    (2, 5, 'Computer Science'),
    (3, 1, 'Cybersecurity'),
    (3, 2, 'Computer Engineering'),
    (3, 3, 'Artificial Intelligence'),
    (3, 4, 'Computer Science'),
    (3, 5, 'IT'),
    (4, 1, 'IT'),
    (4, 2, 'Software Engineering'),
    (4, 3, 'Data Sciences'),
    (4, 4, 'Artificial Intelligence'),
    (4, 5, 'Other')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Software Engineering'),
    (2, 'IT'),
    (3, 'Hardware Engineering'),
    (4, 'Computer Science'),
    (5, 'Data Sciences')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [71/100] AMNA AHMAD (F9 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-amna-ahmad-f09-ics-905@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AMNA AHMAD"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AMNA AHMAD', 'ICS', 'F9 ICS', 'F09-ICS-905', 1127.0, 584.5 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Punjab University Engineering Programs'),
    (1, 2, 'NTU'),
    (1, 3, 'Other'),
    (1, 4, 'GIK'),
    (1, 5, 'NUST'),
    (2, 1, 'ITU'),
    (2, 2, 'Other'),
    (2, 3, 'Bahria University'),
    (2, 4, 'UET Lahore'),
    (2, 5, 'FAST-NUCES'),
    (3, 1, 'COMSATS'),
    (3, 2, 'International Islamic University'),
    (3, 3, 'Air University'),
    (3, 4, 'Bahria University'),
    (3, 5, 'IST'),
    (4, 1, 'NTU'),
    (4, 2, 'Quaid-i-Azam University'),
    (4, 3, 'UET Taxila / Chakwal'),
    (4, 4, 'NUST'),
    (4, 5, 'Bahria University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'IT'),
    (1, 2, 'Data Sciences'),
    (1, 3, 'Cybersecurity'),
    (1, 4, 'Hardware Engineering'),
    (1, 5, 'Software Engineering'),
    (2, 1, 'Computer Engineering'),
    (2, 2, 'Other'),
    (2, 3, 'Artificial Intelligence'),
    (2, 4, 'Hardware Engineering'),
    (2, 5, 'Data Sciences'),
    (3, 1, 'IT'),
    (3, 2, 'Computer Science'),
    (3, 3, 'Hardware Engineering'),
    (3, 4, 'Data Sciences'),
    (3, 5, 'Artificial Intelligence'),
    (4, 1, 'Computer Engineering'),
    (4, 2, 'Other'),
    (4, 3, 'Data Sciences'),
    (4, 4, 'Computer Science'),
    (4, 5, 'Cybersecurity')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Data Sciences'),
    (2, 'Computer Science'),
    (3, 'IT'),
    (4, 'Artificial Intelligence'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [72/100] AMNA FARYAD (F13 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-amna-faryad-f13-ics-1355@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AMNA FARYAD"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AMNA FARYAD', 'ICS', 'F13 ICS', 'F13-ICS-1355', 1115.0, 546.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'International Islamic University'),
    (1, 2, 'PIFD'),
    (1, 3, 'IST'),
    (1, 4, 'NCA'),
    (1, 5, 'NTU'),
    (2, 1, 'UET Taxila / Chakwal'),
    (2, 2, 'NASTP'),
    (2, 3, 'IBA'),
    (2, 4, 'COMSATS'),
    (2, 5, 'NUST'),
    (3, 1, 'LSE'),
    (3, 2, 'International Islamic University'),
    (3, 3, 'Bahria University'),
    (3, 4, 'IBA'),
    (3, 5, 'Other'),
    (4, 1, 'LUMS'),
    (4, 2, 'UET Lahore'),
    (4, 3, 'LSE'),
    (4, 4, 'COMSATS'),
    (4, 5, 'NASTP')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Computer Science'),
    (1, 2, 'Other'),
    (1, 3, 'Data Sciences'),
    (1, 4, 'Cybersecurity'),
    (1, 5, 'Software Engineering'),
    (2, 1, 'Computer Engineering'),
    (2, 2, 'Cybersecurity'),
    (2, 3, 'IT'),
    (2, 4, 'Data Sciences'),
    (2, 5, 'Software Engineering'),
    (3, 1, 'IT'),
    (3, 2, 'Data Sciences'),
    (3, 3, 'Software Engineering'),
    (3, 4, 'Computer Science'),
    (3, 5, 'Other'),
    (4, 1, 'Artificial Intelligence'),
    (4, 2, 'Data Sciences'),
    (4, 3, 'Hardware Engineering'),
    (4, 4, 'Other'),
    (4, 5, 'Computer Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Computer Engineering'),
    (3, 'Other'),
    (4, 'Artificial Intelligence'),
    (5, 'Data Sciences')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [73/100] SARAH RASHID (F8 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-sarah-rashid-f08-ics-804@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"SARAH RASHID"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'SARAH RASHID', 'ICS', 'F8 ICS', 'F08-ICS-804', 1014.0, 519.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'ITU'),
    (1, 2, 'Air University'),
    (1, 3, 'FAST-NUCES'),
    (1, 4, 'IST'),
    (1, 5, 'NCA'),
    (2, 1, 'Punjab University/PUCIT'),
    (2, 2, 'Other'),
    (2, 3, 'Punjab University Engineering Programs'),
    (2, 4, 'COMSATS'),
    (2, 5, 'LSE'),
    (3, 1, 'NUST'),
    (3, 2, 'Quaid-i-Azam University'),
    (3, 3, 'NCA'),
    (3, 4, 'NTU'),
    (3, 5, 'Bahria University'),
    (4, 1, 'Punjab University/PUCIT'),
    (4, 2, 'UET Taxila / Chakwal'),
    (4, 3, 'NASTP'),
    (4, 4, 'LUMS'),
    (4, 5, 'NCA')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Cybersecurity'),
    (1, 2, 'Hardware Engineering'),
    (1, 3, 'Data Sciences'),
    (1, 4, 'Other'),
    (1, 5, 'Artificial Intelligence'),
    (2, 1, 'Hardware Engineering'),
    (2, 2, 'Data Sciences'),
    (2, 3, 'IT'),
    (2, 4, 'Artificial Intelligence'),
    (2, 5, 'Computer Science'),
    (3, 1, 'Artificial Intelligence'),
    (3, 2, 'Software Engineering'),
    (3, 3, 'IT'),
    (3, 4, 'Hardware Engineering'),
    (3, 5, 'Computer Engineering'),
    (4, 1, 'Computer Science'),
    (4, 2, 'Software Engineering'),
    (4, 3, 'Cybersecurity'),
    (4, 4, 'Computer Engineering'),
    (4, 5, 'Data Sciences')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Software Engineering'),
    (3, 'Cybersecurity'),
    (4, 'Data Sciences'),
    (5, 'Hardware Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [74/100] ASIYA (F15 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-asiya-f15-ics-1511@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ASIYA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ASIYA', 'ICS', 'F15 ICS', 'F15-ICS-1511', 848.0, 343.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'ITU'),
    (1, 2, 'NCA'),
    (1, 3, 'Namal'),
    (1, 4, 'UET Lahore'),
    (1, 5, 'Punjab University Engineering Programs'),
    (2, 1, 'NUST'),
    (2, 2, 'IST'),
    (2, 3, 'ITU'),
    (2, 4, 'PIEAS'),
    (2, 5, 'International Islamic University'),
    (3, 1, 'NTU'),
    (3, 2, 'FAST-NUCES'),
    (3, 3, 'UET Lahore'),
    (3, 4, 'IBA'),
    (3, 5, 'LSE'),
    (4, 1, 'LUMS'),
    (4, 2, 'ITU'),
    (4, 3, 'UET Taxila / Chakwal'),
    (4, 4, 'Namal'),
    (4, 5, 'LSE')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Data Sciences'),
    (1, 2, 'Computer Engineering'),
    (1, 3, 'Software Engineering'),
    (1, 4, 'IT'),
    (1, 5, 'Computer Science'),
    (2, 1, 'Hardware Engineering'),
    (2, 2, 'Cybersecurity'),
    (2, 3, 'Software Engineering'),
    (2, 4, 'Data Sciences'),
    (2, 5, 'IT'),
    (3, 1, 'Other'),
    (3, 2, 'Artificial Intelligence'),
    (3, 3, 'Hardware Engineering'),
    (3, 4, 'Software Engineering'),
    (3, 5, 'Data Sciences'),
    (4, 1, 'Hardware Engineering'),
    (4, 2, 'Other'),
    (4, 3, 'Computer Engineering'),
    (4, 4, 'Cybersecurity'),
    (4, 5, 'Computer Science')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Software Engineering'),
    (3, 'Other'),
    (4, 'Data Sciences'),
    (5, 'Artificial Intelligence')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [75/100] FATIMA IJAZ (F16 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-fatima-ijaz-f16-ics-1655@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FATIMA IJAZ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FATIMA IJAZ', 'ICS', 'F16 ICS', 'F16-ICS-1655', 871.0, 382.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NUST'),
    (1, 2, 'Air University'),
    (1, 3, 'ITU'),
    (1, 4, 'Bahria University'),
    (1, 5, 'NTU'),
    (2, 1, 'IST'),
    (2, 2, 'FAST-NUCES'),
    (2, 3, 'LSE'),
    (2, 4, 'International Islamic University'),
    (2, 5, 'NCA'),
    (3, 1, 'PIEAS'),
    (3, 2, 'Bahria University'),
    (3, 3, 'FAST-NUCES'),
    (3, 4, 'UET Taxila / Chakwal'),
    (3, 5, 'IBA'),
    (4, 1, 'NASTP'),
    (4, 2, 'Punjab University Engineering Programs'),
    (4, 3, 'International Islamic University'),
    (4, 4, 'FAST-NUCES'),
    (4, 5, 'Quaid-i-Azam University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Computer Science'),
    (1, 2, 'Computer Engineering'),
    (1, 3, 'Other'),
    (1, 4, 'Data Sciences'),
    (1, 5, 'Software Engineering'),
    (2, 1, 'Data Sciences'),
    (2, 2, 'Hardware Engineering'),
    (2, 3, 'IT'),
    (2, 4, 'Cybersecurity'),
    (2, 5, 'Other'),
    (3, 1, 'Computer Engineering'),
    (3, 2, 'Data Sciences'),
    (3, 3, 'Cybersecurity'),
    (3, 4, 'Software Engineering'),
    (3, 5, 'Artificial Intelligence'),
    (4, 1, 'IT'),
    (4, 2, 'Software Engineering'),
    (4, 3, 'Cybersecurity'),
    (4, 4, 'Computer Science'),
    (4, 5, 'Other')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Hardware Engineering'),
    (2, 'IT'),
    (3, 'Other'),
    (4, 'Computer Science'),
    (5, 'Artificial Intelligence')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [76/100] KHADIJA MANSOOR (F7 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-khadija-mansoor-f07-ics-704@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"KHADIJA MANSOOR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'KHADIJA MANSOOR', 'ICS', 'F7 ICS', 'F07-ICS-704', 1159.0, 526.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Punjab University/PUCIT'),
    (1, 2, 'Quaid-i-Azam University'),
    (1, 3, 'Other'),
    (1, 4, 'COMSATS'),
    (1, 5, 'NASTP'),
    (2, 1, 'NASTP'),
    (2, 2, 'NTU'),
    (2, 3, 'International Islamic University'),
    (2, 4, 'PIEAS'),
    (2, 5, 'IST'),
    (3, 1, 'IBA'),
    (3, 2, 'ITU'),
    (3, 3, 'UET Taxila / Chakwal'),
    (3, 4, 'NCA'),
    (3, 5, 'PIEAS'),
    (4, 1, 'ITU'),
    (4, 2, 'IST'),
    (4, 3, 'NCA'),
    (4, 4, 'GIK'),
    (4, 5, 'NTU')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'Cybersecurity'),
    (1, 3, 'Computer Engineering'),
    (1, 4, 'Hardware Engineering'),
    (1, 5, 'Data Sciences'),
    (2, 1, 'Artificial Intelligence'),
    (2, 2, 'Hardware Engineering'),
    (2, 3, 'Other'),
    (2, 4, 'Computer Engineering'),
    (2, 5, 'Cybersecurity'),
    (3, 1, 'Computer Science'),
    (3, 2, 'Software Engineering'),
    (3, 3, 'IT'),
    (3, 4, 'Other'),
    (3, 5, 'Data Sciences'),
    (4, 1, 'Computer Science'),
    (4, 2, 'Other'),
    (4, 3, 'IT'),
    (4, 4, 'Software Engineering'),
    (4, 5, 'Hardware Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Science'),
    (2, 'Computer Engineering'),
    (3, 'Data Sciences'),
    (4, 'IT'),
    (5, 'Other')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [77/100] MUNTAHA ISHTIAQ (F10 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-muntaha-ishtiaq-f10-ics-1058@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MUNTAHA ISHTIAQ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MUNTAHA ISHTIAQ', 'ICS', 'F10 ICS', 'F10-ICS-1058', 1012.0, 536.5 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'PIEAS'),
    (1, 2, 'International Islamic University'),
    (1, 3, 'ITU'),
    (1, 4, 'UET Lahore'),
    (1, 5, 'IBA'),
    (2, 1, 'Punjab University Engineering Programs'),
    (2, 2, 'Other'),
    (2, 3, 'NUST'),
    (2, 4, 'GIK'),
    (2, 5, 'Bahria University'),
    (3, 1, 'NTU'),
    (3, 2, 'Air University'),
    (3, 3, 'UET Lahore'),
    (3, 4, 'UET Taxila / Chakwal'),
    (3, 5, 'PIFD'),
    (4, 1, 'PIFD'),
    (4, 2, 'Punjab University Engineering Programs'),
    (4, 3, 'UET Lahore'),
    (4, 4, 'LUMS'),
    (4, 5, 'UET Taxila / Chakwal')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Hardware Engineering'),
    (1, 2, 'IT'),
    (1, 3, 'Artificial Intelligence'),
    (1, 4, 'Computer Science'),
    (1, 5, 'Other'),
    (2, 1, 'Hardware Engineering'),
    (2, 2, 'Computer Science'),
    (2, 3, 'Computer Engineering'),
    (2, 4, 'Cybersecurity'),
    (2, 5, 'Data Sciences'),
    (3, 1, 'Artificial Intelligence'),
    (3, 2, 'IT'),
    (3, 3, 'Cybersecurity'),
    (3, 4, 'Hardware Engineering'),
    (3, 5, 'Computer Science'),
    (4, 1, 'Cybersecurity'),
    (4, 2, 'Computer Science'),
    (4, 3, 'Artificial Intelligence'),
    (4, 4, 'Data Sciences'),
    (4, 5, 'Hardware Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Artificial Intelligence'),
    (2, 'Other'),
    (3, 'Cybersecurity'),
    (4, 'Computer Engineering'),
    (5, 'Hardware Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [78/100] MAHROSH AZIZ (F14 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-mahrosh-aziz-f14-ics-1413@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MAHROSH AZIZ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MAHROSH AZIZ', 'ICS', 'F14 ICS', 'F14-ICS-1413', 976.0, 366.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Punjab University Engineering Programs'),
    (1, 2, 'PIEAS'),
    (1, 3, 'NCA'),
    (1, 4, 'COMSATS'),
    (1, 5, 'PIFD'),
    (2, 1, 'GIK'),
    (2, 2, 'NUST'),
    (2, 3, 'Other'),
    (2, 4, 'COMSATS'),
    (2, 5, 'UET Lahore'),
    (3, 1, 'International Islamic University'),
    (3, 2, 'LUMS'),
    (3, 3, 'NTU'),
    (3, 4, 'Namal'),
    (3, 5, 'IBA'),
    (4, 1, 'Namal'),
    (4, 2, 'UET Lahore'),
    (4, 3, 'NTU'),
    (4, 4, 'LUMS'),
    (4, 5, 'COMSATS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Software Engineering'),
    (1, 2, 'Artificial Intelligence'),
    (1, 3, 'Cybersecurity'),
    (1, 4, 'Computer Engineering'),
    (1, 5, 'IT'),
    (2, 1, 'Data Sciences'),
    (2, 2, 'Computer Engineering'),
    (2, 3, 'IT'),
    (2, 4, 'Hardware Engineering'),
    (2, 5, 'Artificial Intelligence'),
    (3, 1, 'Computer Engineering'),
    (3, 2, 'IT'),
    (3, 3, 'Software Engineering'),
    (3, 4, 'Computer Science'),
    (3, 5, 'Other'),
    (4, 1, 'Other'),
    (4, 2, 'Data Sciences'),
    (4, 3, 'Cybersecurity'),
    (4, 4, 'IT'),
    (4, 5, 'Computer Science')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Software Engineering'),
    (2, 'Hardware Engineering'),
    (3, 'IT'),
    (4, 'Data Sciences'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [79/100] NABEERA JAWAD (F9 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-nabeera-jawad-f09-ics-908@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"NABEERA JAWAD"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'NABEERA JAWAD', 'ICS', 'F9 ICS', 'F09-ICS-908', 1114.0, 659.5 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Quaid-i-Azam University'),
    (1, 2, 'Bahria University'),
    (1, 3, 'International Islamic University'),
    (1, 4, 'Punjab University/PUCIT'),
    (1, 5, 'NASTP'),
    (2, 1, 'COMSATS'),
    (2, 2, 'Punjab University/PUCIT'),
    (2, 3, 'LUMS'),
    (2, 4, 'FAST-NUCES'),
    (2, 5, 'Bahria University'),
    (3, 1, 'Other'),
    (3, 2, 'Namal'),
    (3, 3, 'PIFD'),
    (3, 4, 'NUST'),
    (3, 5, 'ITU'),
    (4, 1, 'IBA'),
    (4, 2, 'COMSATS'),
    (4, 3, 'International Islamic University'),
    (4, 4, 'IST'),
    (4, 5, 'FAST-NUCES')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'IT'),
    (1, 2, 'Artificial Intelligence'),
    (1, 3, 'Hardware Engineering'),
    (1, 4, 'Computer Science'),
    (1, 5, 'Cybersecurity'),
    (2, 1, 'Hardware Engineering'),
    (2, 2, 'Software Engineering'),
    (2, 3, 'Data Sciences'),
    (2, 4, 'Computer Engineering'),
    (2, 5, 'Artificial Intelligence'),
    (3, 1, 'IT'),
    (3, 2, 'Hardware Engineering'),
    (3, 3, 'Artificial Intelligence'),
    (3, 4, 'Computer Engineering'),
    (3, 5, 'Cybersecurity'),
    (4, 1, 'Computer Engineering'),
    (4, 2, 'Other'),
    (4, 3, 'Software Engineering'),
    (4, 4, 'Artificial Intelligence'),
    (4, 5, 'Hardware Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Software Engineering'),
    (2, 'IT'),
    (3, 'Computer Engineering'),
    (4, 'Cybersecurity'),
    (5, 'Other')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [80/100] RAFIA QAYYUM (F13 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-rafia-qayyum-f13-ics-1358@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"RAFIA QAYYUM"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'RAFIA QAYYUM', 'ICS', 'F13 ICS', 'F13-ICS-1358', 1094.0, 568.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'IBA'),
    (1, 2, 'Bahria University'),
    (1, 3, 'NCA'),
    (1, 4, 'NASTP'),
    (1, 5, 'NUST'),
    (2, 1, 'COMSATS'),
    (2, 2, 'PIEAS'),
    (2, 3, 'Other'),
    (2, 4, 'IST'),
    (2, 5, 'NTU'),
    (3, 1, 'Namal'),
    (3, 2, 'LUMS'),
    (3, 3, 'Air University'),
    (3, 4, 'UET Lahore'),
    (3, 5, 'Punjab University Engineering Programs'),
    (4, 1, 'FAST-NUCES'),
    (4, 2, 'Punjab University Engineering Programs'),
    (4, 3, 'LSE'),
    (4, 4, 'GIK'),
    (4, 5, 'PIEAS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Computer Science'),
    (1, 2, 'Cybersecurity'),
    (1, 3, 'Data Sciences'),
    (1, 4, 'Hardware Engineering'),
    (1, 5, 'Computer Engineering'),
    (2, 1, 'Software Engineering'),
    (2, 2, 'Hardware Engineering'),
    (2, 3, 'Computer Engineering'),
    (2, 4, 'Other'),
    (2, 5, 'IT'),
    (3, 1, 'Computer Science'),
    (3, 2, 'IT'),
    (3, 3, 'Artificial Intelligence'),
    (3, 4, 'Data Sciences'),
    (3, 5, 'Software Engineering'),
    (4, 1, 'Computer Science'),
    (4, 2, 'Artificial Intelligence'),
    (4, 3, 'Software Engineering'),
    (4, 4, 'Hardware Engineering'),
    (4, 5, 'Cybersecurity')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Engineering'),
    (2, 'Other'),
    (3, 'IT'),
    (4, 'Artificial Intelligence'),
    (5, 'Data Sciences')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [81/100] AREEBA KAYANI (F8 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-areeba-kayani-f08-ics-807@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AREEBA KAYANI"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AREEBA KAYANI', 'ICS', 'F8 ICS', 'F08-ICS-807', 1001.0, 483.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Namal'),
    (1, 2, 'UET Taxila / Chakwal'),
    (1, 3, 'PIEAS'),
    (1, 4, 'NCA'),
    (1, 5, 'UET Lahore'),
    (2, 1, 'Air University'),
    (2, 2, 'NASTP'),
    (2, 3, 'Punjab University Engineering Programs'),
    (2, 4, 'UET Lahore'),
    (2, 5, 'Quaid-i-Azam University'),
    (3, 1, 'NASTP'),
    (3, 2, 'NTU'),
    (3, 3, 'Other'),
    (3, 4, 'NCA'),
    (3, 5, 'GIK'),
    (4, 1, 'LUMS'),
    (4, 2, 'International Islamic University'),
    (4, 3, 'NCA'),
    (4, 4, 'Bahria University'),
    (4, 5, 'PIFD')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Software Engineering'),
    (1, 2, 'Other'),
    (1, 3, 'Data Sciences'),
    (1, 4, 'Computer Science'),
    (1, 5, 'Artificial Intelligence'),
    (2, 1, 'Computer Engineering'),
    (2, 2, 'Hardware Engineering'),
    (2, 3, 'IT'),
    (2, 4, 'Computer Science'),
    (2, 5, 'Software Engineering'),
    (3, 1, 'Data Sciences'),
    (3, 2, 'Hardware Engineering'),
    (3, 3, 'Artificial Intelligence'),
    (3, 4, 'Other'),
    (3, 5, 'Computer Science'),
    (4, 1, 'Artificial Intelligence'),
    (4, 2, 'Computer Engineering'),
    (4, 3, 'Other'),
    (4, 4, 'Data Sciences'),
    (4, 5, 'Computer Science')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Software Engineering'),
    (2, 'Computer Engineering'),
    (3, 'Hardware Engineering'),
    (4, 'Cybersecurity'),
    (5, 'Other')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [82/100] ALIZA NAEEM RANA (F15 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-aliza-naeem-rana-f15-ics-1516@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ALIZA NAEEM RANA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ALIZA NAEEM RANA', 'ICS', 'F15 ICS', 'F15-ICS-1516', 832.0, 110.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'GIK'),
    (1, 2, 'FAST-NUCES'),
    (1, 3, 'IBA'),
    (1, 4, 'PIFD'),
    (1, 5, 'Punjab University/PUCIT'),
    (2, 1, 'Namal'),
    (2, 2, 'Quaid-i-Azam University'),
    (2, 3, 'LUMS'),
    (2, 4, 'Punjab University Engineering Programs'),
    (2, 5, 'UET Lahore'),
    (3, 1, 'PIFD'),
    (3, 2, 'NCA'),
    (3, 3, 'NTU'),
    (3, 4, 'International Islamic University'),
    (3, 5, 'NUST'),
    (4, 1, 'NUST'),
    (4, 2, 'International Islamic University'),
    (4, 3, 'LSE'),
    (4, 4, 'UET Taxila / Chakwal'),
    (4, 5, 'Quaid-i-Azam University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'Computer Science'),
    (1, 3, 'Hardware Engineering'),
    (1, 4, 'Data Sciences'),
    (1, 5, 'IT'),
    (2, 1, 'Artificial Intelligence'),
    (2, 2, 'Cybersecurity'),
    (2, 3, 'Computer Engineering'),
    (2, 4, 'IT'),
    (2, 5, 'Hardware Engineering'),
    (3, 1, 'Artificial Intelligence'),
    (3, 2, 'Cybersecurity'),
    (3, 3, 'Data Sciences'),
    (3, 4, 'Software Engineering'),
    (3, 5, 'Computer Science'),
    (4, 1, 'Artificial Intelligence'),
    (4, 2, 'IT'),
    (4, 3, 'Other'),
    (4, 4, 'Data Sciences'),
    (4, 5, 'Computer Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'Computer Science'),
    (3, 'IT'),
    (4, 'Data Sciences'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [83/100] KHADIJA ARIF (F16 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-khadija-arif-f16-ics-1658@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"KHADIJA ARIF"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'KHADIJA ARIF', 'ICS', 'F16 ICS', 'F16-ICS-1658', 960.0, 365.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NTU'),
    (1, 2, 'PIEAS'),
    (1, 3, 'Namal'),
    (1, 4, 'UET Lahore'),
    (1, 5, 'COMSATS'),
    (2, 1, 'PIFD'),
    (2, 2, 'NASTP'),
    (2, 3, 'COMSATS'),
    (2, 4, 'UET Taxila / Chakwal'),
    (2, 5, 'Punjab University Engineering Programs'),
    (3, 1, 'Other'),
    (3, 2, 'FAST-NUCES'),
    (3, 3, 'Air University'),
    (3, 4, 'COMSATS'),
    (3, 5, 'NTU'),
    (4, 1, 'LSE'),
    (4, 2, 'Bahria University'),
    (4, 3, 'NASTP'),
    (4, 4, 'Punjab University Engineering Programs'),
    (4, 5, 'International Islamic University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Software Engineering'),
    (1, 2, 'Computer Science'),
    (1, 3, 'Other'),
    (1, 4, 'Data Sciences'),
    (1, 5, 'IT'),
    (2, 1, 'Computer Engineering'),
    (2, 2, 'Computer Science'),
    (2, 3, 'Hardware Engineering'),
    (2, 4, 'Other'),
    (2, 5, 'Data Sciences'),
    (3, 1, 'Software Engineering'),
    (3, 2, 'Computer Engineering'),
    (3, 3, 'IT'),
    (3, 4, 'Cybersecurity'),
    (3, 5, 'Data Sciences'),
    (4, 1, 'Computer Engineering'),
    (4, 2, 'Computer Science'),
    (4, 3, 'Software Engineering'),
    (4, 4, 'Cybersecurity'),
    (4, 5, 'IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Engineering'),
    (2, 'Data Sciences'),
    (3, 'Software Engineering'),
    (4, 'Cybersecurity'),
    (5, 'Other')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [84/100] ESHA FAISAL (F7 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-esha-faisal-f07-ics-707@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ESHA FAISAL"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ESHA FAISAL', 'ICS', 'F7 ICS', 'F07-ICS-707', 1153.0, 870.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Air University'),
    (1, 2, 'IBA'),
    (1, 3, 'IST'),
    (1, 4, 'UET Taxila / Chakwal'),
    (1, 5, 'COMSATS'),
    (2, 1, 'Punjab University/PUCIT'),
    (2, 2, 'COMSATS'),
    (2, 3, 'NUST'),
    (2, 4, 'LUMS'),
    (2, 5, 'GIK'),
    (3, 1, 'Air University'),
    (3, 2, 'FAST-NUCES'),
    (3, 3, 'LSE'),
    (3, 4, 'ITU'),
    (3, 5, 'NTU'),
    (4, 1, 'Quaid-i-Azam University'),
    (4, 2, 'NUST'),
    (4, 3, 'Namal'),
    (4, 4, 'NCA'),
    (4, 5, 'NTU')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Cybersecurity'),
    (1, 2, 'Hardware Engineering'),
    (1, 3, 'Software Engineering'),
    (1, 4, 'Artificial Intelligence'),
    (1, 5, 'IT'),
    (2, 1, 'Data Sciences'),
    (2, 2, 'Software Engineering'),
    (2, 3, 'Other'),
    (2, 4, 'Hardware Engineering'),
    (2, 5, 'Artificial Intelligence'),
    (3, 1, 'Software Engineering'),
    (3, 2, 'Computer Science'),
    (3, 3, 'Computer Engineering'),
    (3, 4, 'IT'),
    (3, 5, 'Cybersecurity'),
    (4, 1, 'Hardware Engineering'),
    (4, 2, 'Cybersecurity'),
    (4, 3, 'Software Engineering'),
    (4, 4, 'Other'),
    (4, 5, 'Computer Science')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Artificial Intelligence'),
    (2, 'IT'),
    (3, 'Cybersecurity'),
    (4, 'Computer Engineering'),
    (5, 'Data Sciences')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [85/100] MANAL FAROOQ (F10 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-manal-farooq-f10-ics-1061@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MANAL FAROOQ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MANAL FAROOQ', 'ICS', 'F10 ICS', 'F10-ICS-1061', 972.0, 534.5 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NASTP'),
    (1, 2, 'PIEAS'),
    (1, 3, 'IST'),
    (1, 4, 'NCA'),
    (1, 5, 'UET Lahore'),
    (2, 1, 'PIFD'),
    (2, 2, 'UET Taxila / Chakwal'),
    (2, 3, 'LSE'),
    (2, 4, 'PIEAS'),
    (2, 5, 'NCA'),
    (3, 1, 'NTU'),
    (3, 2, 'Bahria University'),
    (3, 3, 'COMSATS'),
    (3, 4, 'Other'),
    (3, 5, 'ITU'),
    (4, 1, 'COMSATS'),
    (4, 2, 'ITU'),
    (4, 3, 'NCA'),
    (4, 4, 'Namal'),
    (4, 5, 'Air University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Artificial Intelligence'),
    (1, 2, 'Computer Engineering'),
    (1, 3, 'Software Engineering'),
    (1, 4, 'Data Sciences'),
    (1, 5, 'Other'),
    (2, 1, 'Cybersecurity'),
    (2, 2, 'Artificial Intelligence'),
    (2, 3, 'Data Sciences'),
    (2, 4, 'IT'),
    (2, 5, 'Computer Engineering'),
    (3, 1, 'Hardware Engineering'),
    (3, 2, 'Software Engineering'),
    (3, 3, 'Cybersecurity'),
    (3, 4, 'Data Sciences'),
    (3, 5, 'Computer Science'),
    (4, 1, 'Data Sciences'),
    (4, 2, 'Software Engineering'),
    (4, 3, 'Cybersecurity'),
    (4, 4, 'Artificial Intelligence'),
    (4, 5, 'Computer Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'Computer Engineering'),
    (3, 'Computer Science'),
    (4, 'Hardware Engineering'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [86/100] SAIRA ZEESHAN (F14 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-saira-zeeshan-f14-ics-1417@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"SAIRA ZEESHAN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'SAIRA ZEESHAN', 'ICS', 'F14 ICS', 'F14-ICS-1417', 962.0, 454.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'LUMS'),
    (1, 2, 'NUST'),
    (1, 3, 'UET Taxila / Chakwal'),
    (1, 4, 'NASTP'),
    (1, 5, 'IST'),
    (2, 1, 'COMSATS'),
    (2, 2, 'Air University'),
    (2, 3, 'LSE'),
    (2, 4, 'PIFD'),
    (2, 5, 'Namal'),
    (3, 1, 'Namal'),
    (3, 2, 'Other'),
    (3, 3, 'Quaid-i-Azam University'),
    (3, 4, 'PIFD'),
    (3, 5, 'NCA'),
    (4, 1, 'NTU'),
    (4, 2, 'ITU'),
    (4, 3, 'NUST'),
    (4, 4, 'LSE'),
    (4, 5, 'Quaid-i-Azam University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Cybersecurity'),
    (1, 2, 'Artificial Intelligence'),
    (1, 3, 'Computer Science'),
    (1, 4, 'Data Sciences'),
    (1, 5, 'Hardware Engineering'),
    (2, 1, 'Cybersecurity'),
    (2, 2, 'Data Sciences'),
    (2, 3, 'IT'),
    (2, 4, 'Computer Engineering'),
    (2, 5, 'Software Engineering'),
    (3, 1, 'Software Engineering'),
    (3, 2, 'IT'),
    (3, 3, 'Hardware Engineering'),
    (3, 4, 'Other'),
    (3, 5, 'Cybersecurity'),
    (4, 1, 'Hardware Engineering'),
    (4, 2, 'Computer Engineering'),
    (4, 3, 'Cybersecurity'),
    (4, 4, 'IT'),
    (4, 5, 'Artificial Intelligence')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Hardware Engineering'),
    (2, 'Artificial Intelligence'),
    (3, 'Computer Engineering'),
    (4, 'Other'),
    (5, 'Computer Science')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [87/100] SYEDA WAJIHA FATIMA (F9 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-syeda-wajiha-fatima-f09-ics-911@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"SYEDA WAJIHA FATIMA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'SYEDA WAJIHA FATIMA', 'ICS', 'F9 ICS', 'F09-ICS-911', 991.0, 615.5 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'GIK'),
    (1, 2, 'ITU'),
    (1, 3, 'IBA'),
    (1, 4, 'FAST-NUCES'),
    (1, 5, 'COMSATS'),
    (2, 1, 'Namal'),
    (2, 2, 'GIK'),
    (2, 3, 'PIEAS'),
    (2, 4, 'International Islamic University'),
    (2, 5, 'COMSATS'),
    (3, 1, 'Bahria University'),
    (3, 2, 'IBA'),
    (3, 3, 'Namal'),
    (3, 4, 'PIFD'),
    (3, 5, 'International Islamic University'),
    (4, 1, 'GIK'),
    (4, 2, 'Namal'),
    (4, 3, 'COMSATS'),
    (4, 4, 'Punjab University/PUCIT'),
    (4, 5, 'PIFD')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Artificial Intelligence'),
    (1, 2, 'Data Sciences'),
    (1, 3, 'Computer Science'),
    (1, 4, 'Other'),
    (1, 5, 'Cybersecurity'),
    (2, 1, 'Other'),
    (2, 2, 'Hardware Engineering'),
    (2, 3, 'Computer Science'),
    (2, 4, 'Data Sciences'),
    (2, 5, 'IT'),
    (3, 1, 'Other'),
    (3, 2, 'Cybersecurity'),
    (3, 3, 'Artificial Intelligence'),
    (3, 4, 'Software Engineering'),
    (3, 5, 'Data Sciences'),
    (4, 1, 'IT'),
    (4, 2, 'Hardware Engineering'),
    (4, 3, 'Data Sciences'),
    (4, 4, 'Cybersecurity'),
    (4, 5, 'Artificial Intelligence')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Data Sciences'),
    (2, 'Artificial Intelligence'),
    (3, 'Other'),
    (4, 'Software Engineering'),
    (5, 'Computer Science')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [88/100] AMINA KHAN (F13 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-amina-khan-f13-ics-1361@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AMINA KHAN"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AMINA KHAN', 'ICS', 'F13 ICS', 'F13-ICS-1361', 1085.0, 627.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Air University'),
    (1, 2, 'NASTP'),
    (1, 3, 'UET Taxila / Chakwal'),
    (1, 4, 'International Islamic University'),
    (1, 5, 'Namal'),
    (2, 1, 'UET Lahore'),
    (2, 2, 'NASTP'),
    (2, 3, 'Punjab University/PUCIT'),
    (2, 4, 'PIFD'),
    (2, 5, 'LSE'),
    (3, 1, 'PIEAS'),
    (3, 2, 'UET Lahore'),
    (3, 3, 'GIK'),
    (3, 4, 'Namal'),
    (3, 5, 'LUMS'),
    (4, 1, 'PIEAS'),
    (4, 2, 'FAST-NUCES'),
    (4, 3, 'GIK'),
    (4, 4, 'Namal'),
    (4, 5, 'IST')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'IT'),
    (1, 2, 'Computer Science'),
    (1, 3, 'Artificial Intelligence'),
    (1, 4, 'Software Engineering'),
    (1, 5, 'Cybersecurity'),
    (2, 1, 'Computer Engineering'),
    (2, 2, 'Artificial Intelligence'),
    (2, 3, 'Software Engineering'),
    (2, 4, 'Data Sciences'),
    (2, 5, 'Computer Science'),
    (3, 1, 'Cybersecurity'),
    (3, 2, 'Computer Science'),
    (3, 3, 'Other'),
    (3, 4, 'Data Sciences'),
    (3, 5, 'IT'),
    (4, 1, 'Other'),
    (4, 2, 'Computer Science'),
    (4, 3, 'IT'),
    (4, 4, 'Hardware Engineering'),
    (4, 5, 'Data Sciences')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Science'),
    (2, 'Other'),
    (3, 'Computer Engineering'),
    (4, 'Cybersecurity'),
    (5, 'Hardware Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [89/100] UMAMA ANWAAR (F8 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-umama-anwaar-f08-ics-811@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"UMAMA ANWAAR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'UMAMA ANWAAR', 'ICS', 'F8 ICS', 'F08-ICS-811', 984.0, 450.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NASTP'),
    (1, 2, 'NUST'),
    (1, 3, 'NTU'),
    (1, 4, 'LSE'),
    (1, 5, 'Punjab University Engineering Programs'),
    (2, 1, 'Punjab University Engineering Programs'),
    (2, 2, 'NUST'),
    (2, 3, 'GIK'),
    (2, 4, 'NASTP'),
    (2, 5, 'IBA'),
    (3, 1, 'LUMS'),
    (3, 2, 'NTU'),
    (3, 3, 'COMSATS'),
    (3, 4, 'PIFD'),
    (3, 5, 'LSE'),
    (4, 1, 'UET Taxila / Chakwal'),
    (4, 2, 'IST'),
    (4, 3, 'FAST-NUCES'),
    (4, 4, 'Punjab University Engineering Programs'),
    (4, 5, 'Quaid-i-Azam University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Data Sciences'),
    (1, 2, 'Cybersecurity'),
    (1, 3, 'Other'),
    (1, 4, 'Computer Science'),
    (1, 5, 'Artificial Intelligence'),
    (2, 1, 'Artificial Intelligence'),
    (2, 2, 'IT'),
    (2, 3, 'Other'),
    (2, 4, 'Computer Engineering'),
    (2, 5, 'Data Sciences'),
    (3, 1, 'Software Engineering'),
    (3, 2, 'IT'),
    (3, 3, 'Computer Science'),
    (3, 4, 'Data Sciences'),
    (3, 5, 'Cybersecurity'),
    (4, 1, 'Computer Engineering'),
    (4, 2, 'Artificial Intelligence'),
    (4, 3, 'Other'),
    (4, 4, 'Hardware Engineering'),
    (4, 5, 'Software Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'Computer Science'),
    (3, 'Data Sciences'),
    (4, 'Computer Engineering'),
    (5, 'Hardware Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [90/100] MAHEEN BABAR (F15 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-maheen-babar-f15-ics-1519@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"MAHEEN BABAR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'MAHEEN BABAR', 'ICS', 'F15 ICS', 'F15-ICS-1519', 824.0, 194.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NCA'),
    (1, 2, 'International Islamic University'),
    (1, 3, 'FAST-NUCES'),
    (1, 4, 'PIEAS'),
    (1, 5, 'PIFD'),
    (2, 1, 'ITU'),
    (2, 2, 'Air University'),
    (2, 3, 'Punjab University Engineering Programs'),
    (2, 4, 'NCA'),
    (2, 5, 'Punjab University/PUCIT'),
    (3, 1, 'NTU'),
    (3, 2, 'COMSATS'),
    (3, 3, 'ITU'),
    (3, 4, 'Punjab University Engineering Programs'),
    (3, 5, 'PIFD'),
    (4, 1, 'NUST'),
    (4, 2, 'UET Taxila / Chakwal'),
    (4, 3, 'Quaid-i-Azam University'),
    (4, 4, 'LUMS'),
    (4, 5, 'IBA')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Cybersecurity'),
    (1, 2, 'Hardware Engineering'),
    (1, 3, 'Data Sciences'),
    (1, 4, 'IT'),
    (1, 5, 'Other'),
    (2, 1, 'Data Sciences'),
    (2, 2, 'Computer Science'),
    (2, 3, 'Cybersecurity'),
    (2, 4, 'Computer Engineering'),
    (2, 5, 'Other'),
    (3, 1, 'IT'),
    (3, 2, 'Other'),
    (3, 3, 'Data Sciences'),
    (3, 4, 'Hardware Engineering'),
    (3, 5, 'Computer Engineering'),
    (4, 1, 'Computer Science'),
    (4, 2, 'Software Engineering'),
    (4, 3, 'Hardware Engineering'),
    (4, 4, 'Data Sciences'),
    (4, 5, 'IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Computer Engineering'),
    (2, 'Artificial Intelligence'),
    (3, 'Software Engineering'),
    (4, 'Hardware Engineering'),
    (5, 'IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [91/100] FATIMA QADEER (F7 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-fatima-qadeer-f07-ics-710@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"FATIMA QADEER"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'FATIMA QADEER', 'ICS', 'F7 ICS', 'F07-ICS-710', 1150.0, 395.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Punjab University/PUCIT'),
    (1, 2, 'Punjab University Engineering Programs'),
    (1, 3, 'NTU'),
    (1, 4, 'Quaid-i-Azam University'),
    (1, 5, 'UET Lahore'),
    (2, 1, 'Bahria University'),
    (2, 2, 'UET Taxila / Chakwal'),
    (2, 3, 'LSE'),
    (2, 4, 'NTU'),
    (2, 5, 'NASTP'),
    (3, 1, 'ITU'),
    (3, 2, 'Air University'),
    (3, 3, 'Punjab University Engineering Programs'),
    (3, 4, 'NCA'),
    (3, 5, 'LSE'),
    (4, 1, 'Namal'),
    (4, 2, 'Punjab University/PUCIT'),
    (4, 3, 'UET Lahore'),
    (4, 4, 'PIEAS'),
    (4, 5, 'Quaid-i-Azam University')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'IT'),
    (1, 2, 'Hardware Engineering'),
    (1, 3, 'Artificial Intelligence'),
    (1, 4, 'Computer Engineering'),
    (1, 5, 'Computer Science'),
    (2, 1, 'Hardware Engineering'),
    (2, 2, 'Software Engineering'),
    (2, 3, 'Data Sciences'),
    (2, 4, 'Computer Engineering'),
    (2, 5, 'Cybersecurity'),
    (3, 1, 'Data Sciences'),
    (3, 2, 'Other'),
    (3, 3, 'Cybersecurity'),
    (3, 4, 'Computer Engineering'),
    (3, 5, 'Artificial Intelligence'),
    (4, 1, 'Artificial Intelligence'),
    (4, 2, 'Other'),
    (4, 3, 'Computer Engineering'),
    (4, 4, 'Data Sciences'),
    (4, 5, 'Hardware Engineering')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'Hardware Engineering'),
    (3, 'IT'),
    (4, 'Data Sciences'),
    (5, 'Software Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [92/100] AREEBA (F10 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-areeba-f10-ics-1064@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AREEBA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AREEBA', 'ICS', 'F10 ICS', 'F10-ICS-1064', 941.0, 449.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'FAST-NUCES'),
    (1, 2, 'Punjab University Engineering Programs'),
    (1, 3, 'COMSATS'),
    (1, 4, 'UET Lahore'),
    (1, 5, 'Bahria University'),
    (2, 1, 'NCA'),
    (2, 2, 'COMSATS'),
    (2, 3, 'ITU'),
    (2, 4, 'NTU'),
    (2, 5, 'International Islamic University'),
    (3, 1, 'International Islamic University'),
    (3, 2, 'UET Lahore'),
    (3, 3, 'UET Taxila / Chakwal'),
    (3, 4, 'GIK'),
    (3, 5, 'LUMS'),
    (4, 1, 'ITU'),
    (4, 2, 'Quaid-i-Azam University'),
    (4, 3, 'Bahria University'),
    (4, 4, 'PIFD'),
    (4, 5, 'LUMS')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'Computer Engineering'),
    (1, 3, 'Software Engineering'),
    (1, 4, 'IT'),
    (1, 5, 'Hardware Engineering'),
    (2, 1, 'Computer Science'),
    (2, 2, 'IT'),
    (2, 3, 'Data Sciences'),
    (2, 4, 'Other'),
    (2, 5, 'Hardware Engineering'),
    (3, 1, 'Computer Engineering'),
    (3, 2, 'IT'),
    (3, 3, 'Cybersecurity'),
    (3, 4, 'Other'),
    (3, 5, 'Data Sciences'),
    (4, 1, 'Hardware Engineering'),
    (4, 2, 'Computer Engineering'),
    (4, 3, 'Computer Science'),
    (4, 4, 'Software Engineering'),
    (4, 5, 'IT')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Software Engineering'),
    (3, 'Computer Engineering'),
    (4, 'Computer Science'),
    (5, 'IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [93/100] HOORAIN TUFAIL (F14 ICS, ICS) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-hoorain-tufail-f14-ics-1421@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"HOORAIN TUFAIL"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'HOORAIN TUFAIL', 'ICS', 'F14 ICS', 'F14-ICS-1421', 953.0, 672.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'NASTP'),
    (1, 2, 'Punjab University Engineering Programs'),
    (1, 3, 'IST'),
    (1, 4, 'Bahria University'),
    (1, 5, 'Namal'),
    (2, 1, 'UET Taxila / Chakwal'),
    (2, 2, 'PIFD'),
    (2, 3, 'Quaid-i-Azam University'),
    (2, 4, 'NASTP'),
    (2, 5, 'ITU'),
    (3, 1, 'LUMS'),
    (3, 2, 'PIEAS'),
    (3, 3, 'International Islamic University'),
    (3, 4, 'COMSATS'),
    (3, 5, 'NUST'),
    (4, 1, 'NASTP'),
    (4, 2, 'LSE'),
    (4, 3, 'Bahria University'),
    (4, 4, 'NUST'),
    (4, 5, 'Punjab University Engineering Programs')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Data Sciences'),
    (1, 2, 'Hardware Engineering'),
    (1, 3, 'Cybersecurity'),
    (1, 4, 'Other'),
    (1, 5, 'IT'),
    (2, 1, 'Computer Engineering'),
    (2, 2, 'IT'),
    (2, 3, 'Data Sciences'),
    (2, 4, 'Computer Science'),
    (2, 5, 'Cybersecurity'),
    (3, 1, 'Hardware Engineering'),
    (3, 2, 'Computer Science'),
    (3, 3, 'Other'),
    (3, 4, 'Data Sciences'),
    (3, 5, 'Software Engineering'),
    (4, 1, 'IT'),
    (4, 2, 'Cybersecurity'),
    (4, 3, 'Computer Engineering'),
    (4, 4, 'Other'),
    (4, 5, 'Data Sciences')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'computer_it'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'Computer Science'),
    (3, 'Software Engineering'),
    (4, 'IT'),
    (5, 'Computer Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [94/100] SHIREEN ZAHRA (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-shireen-zahra-f06-pe-619@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"SHIREEN ZAHRA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'SHIREEN ZAHRA', 'Pre-Engineering', 'F6 PE', 'F06-PE-619', 1089.0, 501.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'PIFD'),
    (1, 2, 'Quaid-i-Azam University'),
    (1, 3, 'Namal'),
    (1, 4, 'UET Lahore'),
    (1, 5, 'IST'),
    (2, 1, 'Punjab University/PUCIT'),
    (2, 2, 'NUST'),
    (2, 3, 'Bahria University'),
    (2, 4, 'Air University'),
    (2, 5, 'UET Taxila / Chakwal'),
    (3, 1, 'GIK'),
    (3, 2, 'Air University'),
    (3, 3, 'International Islamic University'),
    (3, 4, 'Punjab University Engineering Programs'),
    (3, 5, 'UET Taxila / Chakwal'),
    (4, 1, 'Punjab University Engineering Programs'),
    (4, 2, 'NUST'),
    (4, 3, 'GIK'),
    (4, 4, 'ITU'),
    (4, 5, 'PIFD')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Agricultural'),
    (1, 2, 'Civil'),
    (1, 3, 'Mechatronics'),
    (1, 4, 'Metallurgical'),
    (1, 5, 'Architectural'),
    (2, 1, 'Transportation'),
    (2, 2, 'Mechanical'),
    (2, 3, 'Biomedical'),
    (2, 4, 'Other'),
    (2, 5, 'Mining'),
    (3, 1, 'Avionics'),
    (3, 2, 'Petroleum'),
    (3, 3, 'Industrial & Manufacturing'),
    (3, 4, 'Telecommunication'),
    (3, 5, 'Mechanical'),
    (4, 1, 'Transportation'),
    (4, 2, 'Biomedical'),
    (4, 3, 'Polymer'),
    (4, 4, 'Metallurgical'),
    (4, 5, 'Other')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Data Sciences'),
    (3, 'Software Engineering'),
    (4, 'Computer Science'),
    (5, 'Computer Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [95/100] KHIZRA TARIQ (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-khizra-tariq-f13-pe-1302@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"KHIZRA TARIQ"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'KHIZRA TARIQ', 'Pre-Engineering', 'F13 PE', 'F13-PE-1302', 1161.0, 626.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'IBA'),
    (1, 2, 'International Islamic University'),
    (1, 3, 'PIEAS'),
    (1, 4, 'Air University'),
    (1, 5, 'PIFD'),
    (2, 1, 'GIK'),
    (2, 2, 'Quaid-i-Azam University'),
    (2, 3, 'UET Lahore'),
    (2, 4, 'LSE'),
    (2, 5, 'NTU'),
    (3, 1, 'NCA'),
    (3, 2, 'Punjab University/PUCIT'),
    (3, 3, 'PIEAS'),
    (3, 4, 'Bahria University'),
    (3, 5, 'COMSATS'),
    (4, 1, 'LUMS'),
    (4, 2, 'ITU'),
    (4, 3, 'IST'),
    (4, 4, 'Punjab University/PUCIT'),
    (4, 5, 'NUST')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Mechanical'),
    (1, 2, 'Architectural'),
    (1, 3, 'Aeronautical'),
    (1, 4, 'Environmental'),
    (1, 5, 'Architecture'),
    (2, 1, 'Architecture'),
    (2, 2, 'Agricultural'),
    (2, 3, 'Other'),
    (2, 4, 'Textile'),
    (2, 5, 'Petroleum'),
    (3, 1, 'Other'),
    (3, 2, 'Petroleum'),
    (3, 3, 'Electrical'),
    (3, 4, 'Telecommunication'),
    (3, 5, 'Polymer'),
    (4, 1, 'Architecture'),
    (4, 2, 'Aeronautical'),
    (4, 3, 'Transportation'),
    (4, 4, 'Other'),
    (4, 5, 'Environmental')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'IT'),
    (2, 'Other'),
    (3, 'Software Engineering'),
    (4, 'Cybersecurity'),
    (5, 'Computer Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [96/100] UMM E FARWA (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-umm-e-farwa-f06-pe-602@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"UMM E FARWA"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'UMM E FARWA', 'Pre-Engineering', 'F6 PE', 'F06-PE-602', 1153.0, 678.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Other'),
    (1, 2, 'NASTP'),
    (1, 3, 'UET Taxila / Chakwal'),
    (1, 4, 'PIEAS'),
    (1, 5, 'International Islamic University'),
    (2, 1, 'IST'),
    (2, 2, 'PIFD'),
    (2, 3, 'Punjab University/PUCIT'),
    (2, 4, 'Air University'),
    (2, 5, 'IBA'),
    (3, 1, 'LUMS'),
    (3, 2, 'ITU'),
    (3, 3, 'FAST-NUCES'),
    (3, 4, 'International Islamic University'),
    (3, 5, 'COMSATS'),
    (4, 1, 'International Islamic University'),
    (4, 2, 'LSE'),
    (4, 3, 'Other'),
    (4, 4, 'Bahria University'),
    (4, 5, 'UET Taxila / Chakwal')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Mechatronics'),
    (1, 2, 'Industrial & Manufacturing'),
    (1, 3, 'Environmental'),
    (1, 4, 'Architectural'),
    (1, 5, 'Civil'),
    (2, 1, 'Other'),
    (2, 2, 'Environmental'),
    (2, 3, 'Polymer'),
    (2, 4, 'Civil'),
    (2, 5, 'Chemical'),
    (3, 1, 'Metallurgical'),
    (3, 2, 'Polymer'),
    (3, 3, 'Electronics'),
    (3, 4, 'Transportation'),
    (3, 5, 'Environmental'),
    (4, 1, 'Chemical'),
    (4, 2, 'Aerospace'),
    (4, 3, 'Mechanical'),
    (4, 4, 'Mechatronics'),
    (4, 5, 'Electrical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Data Sciences'),
    (2, 'Other'),
    (3, 'Computer Science'),
    (4, 'Artificial Intelligence'),
    (5, 'IT')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [97/100] LAIBA NAYYER (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-laiba-nayyer-f13-pe-1325@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"LAIBA NAYYER"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'LAIBA NAYYER', 'Pre-Engineering', 'F13 PE', 'F13-PE-1325', 605.0, 412.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Air University'),
    (1, 2, 'ITU'),
    (1, 3, 'UET Taxila / Chakwal'),
    (1, 4, 'Punjab University Engineering Programs'),
    (1, 5, 'NUST'),
    (2, 1, 'NUST'),
    (2, 2, 'PIEAS'),
    (2, 3, 'NASTP'),
    (2, 4, 'International Islamic University'),
    (2, 5, 'Bahria University'),
    (3, 1, 'NCA'),
    (3, 2, 'NUST'),
    (3, 3, 'Punjab University/PUCIT'),
    (3, 4, 'IST'),
    (3, 5, 'PIFD'),
    (4, 1, 'IST'),
    (4, 2, 'Other'),
    (4, 3, 'GIK'),
    (4, 4, 'COMSATS'),
    (4, 5, 'LSE')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Aeronautical'),
    (1, 2, 'Petroleum'),
    (1, 3, 'Mechanical'),
    (1, 4, 'Architecture'),
    (1, 5, 'Electrical'),
    (2, 1, 'Electrical'),
    (2, 2, 'Mining'),
    (2, 3, 'Architecture'),
    (2, 4, 'Environmental'),
    (2, 5, 'Transportation'),
    (3, 1, 'Chemical'),
    (3, 2, 'Aeronautical'),
    (3, 3, 'Telecommunication'),
    (3, 4, 'Agricultural'),
    (3, 5, 'Civil'),
    (4, 1, 'Environmental'),
    (4, 2, 'Avionics'),
    (4, 3, 'Metallurgical'),
    (4, 4, 'Mining'),
    (4, 5, 'Chemical')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Artificial Intelligence'),
    (2, 'Other'),
    (3, 'Computer Engineering'),
    (4, 'IT'),
    (5, 'Cybersecurity')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [98/100] AYESHA ZAHID (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-ayesha-zahid-f06-pe-626@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"AYESHA ZAHID"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'AYESHA ZAHID', 'Pre-Engineering', 'F6 PE', 'F06-PE-626', 1051.0, 664.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Quaid-i-Azam University'),
    (1, 2, 'NUST'),
    (1, 3, 'Namal'),
    (1, 4, 'Bahria University'),
    (1, 5, 'PIFD'),
    (2, 1, 'IBA'),
    (2, 2, 'FAST-NUCES'),
    (2, 3, 'NTU'),
    (2, 4, 'LUMS'),
    (2, 5, 'Quaid-i-Azam University'),
    (3, 1, 'GIK'),
    (3, 2, 'Other'),
    (3, 3, 'NCA'),
    (3, 4, 'COMSATS'),
    (3, 5, 'LUMS'),
    (4, 1, 'NTU'),
    (4, 2, 'NASTP'),
    (4, 3, 'Quaid-i-Azam University'),
    (4, 4, 'ITU'),
    (4, 5, 'Punjab University/PUCIT')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Electronics'),
    (1, 2, 'Aeronautical'),
    (1, 3, 'Mechanical'),
    (1, 4, 'Architecture'),
    (1, 5, 'Other'),
    (2, 1, 'Petroleum'),
    (2, 2, 'Chemical'),
    (2, 3, 'Architecture'),
    (2, 4, 'Polymer'),
    (2, 5, 'Aeronautical'),
    (3, 1, 'Mining'),
    (3, 2, 'Mechanical'),
    (3, 3, 'Mechatronics'),
    (3, 4, 'Polymer'),
    (3, 5, 'Textile'),
    (4, 1, 'Architectural'),
    (4, 2, 'Transportation'),
    (4, 3, 'Electrical'),
    (4, 4, 'Mechatronics'),
    (4, 5, 'Avionics')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Other'),
    (2, 'Cybersecurity'),
    (3, 'Computer Engineering'),
    (4, 'IT'),
    (5, 'Computer Science')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [99/100] ZAINAB ZUBAIR (F6 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-zainab-zubair-f06-pe-639@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"ZAINAB ZUBAIR"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'ZAINAB ZUBAIR', 'Pre-Engineering', 'F6 PE', 'F06-PE-639', 769.0, 330.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'COMSATS'),
    (1, 2, 'IBA'),
    (1, 3, 'Namal'),
    (1, 4, 'International Islamic University'),
    (1, 5, 'LUMS'),
    (2, 1, 'Punjab University/PUCIT'),
    (2, 2, 'Punjab University Engineering Programs'),
    (2, 3, 'Quaid-i-Azam University'),
    (2, 4, 'Other'),
    (2, 5, 'NTU'),
    (3, 1, 'Bahria University'),
    (3, 2, 'FAST-NUCES'),
    (3, 3, 'UET Lahore'),
    (3, 4, 'Quaid-i-Azam University'),
    (3, 5, 'NASTP'),
    (4, 1, 'ITU'),
    (4, 2, 'Air University'),
    (4, 3, 'NASTP'),
    (4, 4, 'PIFD'),
    (4, 5, 'Namal')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Textile'),
    (1, 2, 'Mechanical'),
    (1, 3, 'Aerospace'),
    (1, 4, 'Metallurgical'),
    (1, 5, 'Telecommunication'),
    (2, 1, 'Polymer'),
    (2, 2, 'Biomedical'),
    (2, 3, 'Aerospace'),
    (2, 4, 'Aeronautical'),
    (2, 5, 'Architecture'),
    (3, 1, 'Mining'),
    (3, 2, 'Avionics'),
    (3, 3, 'Mechanical'),
    (3, 4, 'Mechatronics'),
    (3, 5, 'Agricultural'),
    (4, 1, 'Metallurgical'),
    (4, 2, 'Avionics'),
    (4, 3, 'Agricultural'),
    (4, 4, 'Environmental'),
    (4, 5, 'Electronics')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Cybersecurity'),
    (2, 'Artificial Intelligence'),
    (3, 'Hardware Engineering'),
    (4, 'Data Sciences'),
    (5, 'Computer Engineering')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';

-- ---- [100/100] INSHAL BANO ABBASI (F13 PE, Pre-Engineering) ----
with new_user as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    email_change_token_current, reauthentication_token
  ) values (
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
    'loadtest-inshal-bano-abbasi-f13-pe-1311@loadtest.rah.internal', 'not-a-real-password-hash-loadtest-only', now(),
    '{"provider":"loadtest","providers":["loadtest"]}'::jsonb, '{"full_name":"INSHAL BANO ABBASI"}'::jsonb, now(), now(),
    '', '', '', '', '', ''
  )
  returning id
),
new_student as (
  insert into public.students (id, student_name, discipline, section, roll_number, matric_marks, first_year_marks)
  select id, 'INSHAL BANO ABBASI', 'Pre-Engineering', 'F13 PE', 'F13-PE-1311', 1038.0, 433.0 from new_user
  returning id
),
new_fp as (
  insert into public.future_pathways (student_id, pathway, status, submitted_at)
  select id, 'engineering', 'submitted', now() from new_student
  returning id
),
inst_prefs as (
  insert into public.student_institute_preferences (future_pathway_id, preference_group, rank, institute_id)
  select new_fp.id, v.grp, v.rnk, i.id
  from new_fp,
    (values
    (1, 1, 'Bahria University'),
    (1, 2, 'PIEAS'),
    (1, 3, 'Other'),
    (1, 4, 'Namal'),
    (1, 5, 'NASTP'),
    (2, 1, 'NASTP'),
    (2, 2, 'FAST-NUCES'),
    (2, 3, 'PIFD'),
    (2, 4, 'Quaid-i-Azam University'),
    (2, 5, 'NTU'),
    (3, 1, 'UET Lahore'),
    (3, 2, 'Namal'),
    (3, 3, 'Air University'),
    (3, 4, 'Bahria University'),
    (3, 5, 'PIEAS'),
    (4, 1, 'International Islamic University'),
    (4, 2, 'Other'),
    (4, 3, 'Namal'),
    (4, 4, 'PIEAS'),
    (4, 5, 'NTU')
    ) as v(grp, rnk, name)
    join public.institutes i on i.name = v.name and i.pathway = 'engineering'
  returning 1
),
fac_prefs as (
  insert into public.student_faculty_preferences (future_pathway_id, preference_group, rank, faculty_id)
  select new_fp.id, v.grp, v.rnk, f.id
  from new_fp,
    (values
    (1, 1, 'Petroleum'),
    (1, 2, 'Electronics'),
    (1, 3, 'Polymer'),
    (1, 4, 'Mining'),
    (1, 5, 'Industrial & Manufacturing'),
    (2, 1, 'Civil'),
    (2, 2, 'Petroleum'),
    (2, 3, 'Chemical'),
    (2, 4, 'Architectural'),
    (2, 5, 'Aerospace'),
    (3, 1, 'Civil'),
    (3, 2, 'Petroleum'),
    (3, 3, 'Industrial & Manufacturing'),
    (3, 4, 'Aeronautical'),
    (3, 5, 'Architectural'),
    (4, 1, 'Telecommunication'),
    (4, 2, 'Agricultural'),
    (4, 3, 'Industrial & Manufacturing'),
    (4, 4, 'Other'),
    (4, 5, 'Textile')
    ) as v(grp, rnk, name)
    join public.fp_faculties f on f.name = v.name and f.pathway = 'engineering' and f.category = 'engineering'
  returning 1
)
insert into public.student_program_preferences (future_pathway_id, rank, program_id)
select new_fp.id, v.rnk, p.id
from new_fp,
  (values
    (1, 'Hardware Engineering'),
    (2, 'Data Sciences'),
    (3, 'Computer Engineering'),
    (4, 'Software Engineering'),
    (5, 'Artificial Intelligence')
  ) as v(rnk, name)
  join public.program_options p on p.name = v.name and p.pathway = 'engineering';
