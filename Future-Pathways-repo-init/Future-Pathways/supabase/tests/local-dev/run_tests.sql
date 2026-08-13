-- ============================================================================
-- Future Pathways migration — correction verification test suite
-- Run as postgres superuser against a database with 000/001/002/003 applied
-- plus 999_test_harness_grants.sql.
-- Uses a lightweight PASS/FAIL convention: each test raises an exception on
-- failure (caught and reported), and prints PASS on success.
-- ============================================================================

\set ON_ERROR_STOP off
\pset pager off

-- ---------------------------------------------------------------------------
-- Fixture data (minimal, just enough to exercise every FK path we touch)
-- ---------------------------------------------------------------------------
begin;

insert into auth.users (id, email) values
    ('11111111-1111-1111-1111-111111111111', 'student.a@test.local'),
    ('22222222-2222-2222-2222-222222222222', 'admin.a@test.local');

insert into public.universities (id, name, city) values
    ('a0000000-0000-0000-0000-000000000001', 'Test University', 'Lahore');

insert into public.campuses (id, university_id, name, city) values
    ('a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Main Campus', 'Lahore');

insert into public.faculties (id, university_id, name) values
    ('a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Faculty of Computing');

insert into public.programs (id, name) values
    ('a0000000-0000-0000-0000-000000000004', 'BS Computer Science');

insert into public.program_offerings (id, program_id, campus_id, faculty_id) values
    ('a0000000-0000-0000-0000-000000000005',
     'a0000000-0000-0000-0000-000000000004',
     'a0000000-0000-0000-0000-000000000002',
     'a0000000-0000-0000-0000-000000000003');

insert into public.admission_cycles (id, university_id, name, year) values
    ('a0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000001', 'Fall 2026', 2026);

insert into public.merit_categories (id, name) values
    ('a0000000-0000-0000-0000-000000000007', 'Open Merit');

insert into public.student_profiles (id, user_id, full_name) values
    ('a0000000-0000-0000-0000-000000000008', '11111111-1111-1111-1111-111111111111', 'Student A');

insert into public.assessment_questions (id, question_text, question_type, display_order) values
    ('a0000000-0000-0000-0000-000000000009', 'Do you prefer research or industry?', 'single_choice', 1);

insert into public.assessment_sessions (id, student_profile_id, questionnaire_version) values
    ('a0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000008', 1);

insert into public.data_sources (id, source_name) values
    ('a0000000-0000-0000-0000-00000000000b', 'Manual entry');

commit;

-- ---------------------------------------------------------------------------
-- TEST 1: merit_position column exists and is usable (Correction #1)
-- ---------------------------------------------------------------------------
do $$
begin
    insert into public.merit_records
        (program_offering_id, admission_cycle_id, merit_category_id, merit_value_type, closing_value, merit_position)
    values
        ('a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000006',
         'a0000000-0000-0000-0000-000000000007', 'percentage', 92.5, 3);
    raise notice 'TEST 1 (merit_position column works): PASS';
exception when undefined_column then
    raise notice 'TEST 1 (merit_position column works): FAIL - column missing (%)', sqlerrm;
end $$;

do $$
begin
    perform 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'merit_records' and column_name = 'closing_rank';
    if found then
        raise notice 'TEST 1b (closing_rank removed): FAIL - old column still present';
    else
        raise notice 'TEST 1b (closing_rank removed): PASS';
    end if;
end $$;

-- ---------------------------------------------------------------------------
-- TEST 2: admission_deadlines.program_offering_id is nullable (Correction #2)
-- ---------------------------------------------------------------------------
do $$
begin
    insert into public.admission_deadlines (admission_cycle_id, deadline_type, deadline_date)
    values ('a0000000-0000-0000-0000-000000000006', 'university_wide_close', now() + interval '30 days');
    raise notice 'TEST 2 (cycle-wide deadline with null program_offering_id): PASS';
exception when not_null_violation then
    raise notice 'TEST 2 (cycle-wide deadline with null program_offering_id): FAIL - still NOT NULL';
end $$;

-- ---------------------------------------------------------------------------
-- TEST 3: recommendation_results.assessment_session_id is NOT NULL (Correction #3)
-- ---------------------------------------------------------------------------
do $$
begin
    insert into public.recommendation_results
        (student_profile_id, program_offering_id, eligibility_status, recommendation_band, algorithm_version)
    values
        ('a0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000005',
         'eligible', 'target', 'v1');
    raise notice 'TEST 3 (recommendation_result without session accepted): FAIL - should have been rejected';
exception when not_null_violation then
    raise notice 'TEST 3 (recommendation_result without session rejected): PASS';
end $$;

do $$
begin
    insert into public.recommendation_results
        (student_profile_id, assessment_session_id, program_offering_id, eligibility_status, recommendation_band, algorithm_version)
    values
        ('a0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000010',
         'a0000000-0000-0000-0000-000000000005', 'eligible', 'target', 'v1');
    raise notice 'TEST 3b (recommendation_result with valid session accepted): PASS';
exception when others then
    raise notice 'TEST 3b (recommendation_result with valid session accepted): FAIL - %', sqlerrm;
end $$;

-- ---------------------------------------------------------------------------
-- TEST 4: ranked student_preferences (Correction #4)
-- ---------------------------------------------------------------------------
do $$
begin
    insert into public.student_preferences
        (student_profile_id, preference_type, preferred_field, preferred_city, budget_min, budget_max)
    values
        ('a0000000-0000-0000-0000-000000000008', 'general', 'Computer Science', 'Lahore', 100000, 500000);

    insert into public.student_preferences
        (student_profile_id, preference_type, preference_rank, university_id)
    values
        ('a0000000-0000-0000-0000-000000000008', 'university', 1, 'a0000000-0000-0000-0000-000000000001');

    insert into public.student_preferences
        (student_profile_id, preference_type, preference_rank, program_offering_id)
    values
        ('a0000000-0000-0000-0000-000000000008', 'program_offering', 1, 'a0000000-0000-0000-0000-000000000005');

    raise notice 'TEST 4 (ranked multi-row preferences insert): PASS';
exception when others then
    raise notice 'TEST 4 (ranked multi-row preferences insert): FAIL - %', sqlerrm;
end $$;

-- TEST 4b: invalid preference target (type/column mismatch) must be rejected
do $$
begin
    insert into public.student_preferences
        (student_profile_id, preference_type, preference_rank, university_id, program_offering_id)
    values
        ('a0000000-0000-0000-0000-000000000008', 'university', 2,
         'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000005');
    raise notice 'TEST 4b (type/target mismatch rejected): FAIL - should have been rejected';
exception when check_violation then
    raise notice 'TEST 4b (type/target mismatch rejected): PASS';
end $$;

-- TEST 4c: ranked row with no rank must be rejected
do $$
begin
    insert into public.student_preferences
        (student_profile_id, preference_type, university_id)
    values
        ('a0000000-0000-0000-0000-000000000008', 'university', 'a0000000-0000-0000-0000-000000000001');
    raise notice 'TEST 4c (ranked row missing rank rejected): FAIL - should have been rejected';
exception when check_violation then
    raise notice 'TEST 4c (ranked row missing rank rejected): PASS';
end $$;

-- TEST 4d: second 'general' row for same student must be rejected
do $$
begin
    insert into public.student_preferences (student_profile_id, preference_type, preferred_city)
    values ('a0000000-0000-0000-0000-000000000008', 'general', 'Karachi');
    raise notice 'TEST 4d (second general row rejected): FAIL - should have been rejected';
exception when unique_violation then
    raise notice 'TEST 4d (second general row rejected): PASS';
end $$;

-- ---------------------------------------------------------------------------
-- TEST 5: finalized-cycle protection reaches merit_records/fee_records
--         (Correction #5)
-- ---------------------------------------------------------------------------
insert into public.fee_records (id, program_offering_id, admission_cycle_id, fee_type, amount)
values ('a0000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-000000000005',
        'a0000000-0000-0000-0000-000000000006', 'tuition', 150000);

do $$
begin
    -- Cycle not finalized yet: update should succeed.
    update public.fee_records set amount = 160000 where id = 'a0000000-0000-0000-0000-00000000000a';
    raise notice 'TEST 5a (fee_records update before cycle finalized): PASS';
exception when others then
    raise notice 'TEST 5a (fee_records update before cycle finalized): FAIL - %', sqlerrm;
end $$;

update public.admission_cycles set is_finalized = true where id = 'a0000000-0000-0000-0000-000000000006';

do $$
begin
    update public.fee_records set amount = 170000 where id = 'a0000000-0000-0000-0000-00000000000a';
    raise notice 'TEST 5b (fee_records update after CYCLE finalized, row itself not finalized): FAIL - should have been blocked';
exception when raise_exception then
    raise notice 'TEST 5b (fee_records update after CYCLE finalized, row itself not finalized): PASS';
end $$;

do $$
begin
    delete from public.fee_records where id = 'a0000000-0000-0000-0000-00000000000a';
    raise notice 'TEST 5c (fee_records delete after cycle finalized): FAIL - should have been blocked';
exception when raise_exception then
    raise notice 'TEST 5c (fee_records delete after cycle finalized): PASS';
end $$;

-- reset for cleanliness
update public.admission_cycles set is_finalized = false where id = 'a0000000-0000-0000-0000-000000000006';

-- ---------------------------------------------------------------------------
-- TEST 6: recommendation_reasons supporting_table/supporting_record_id
--         (Correction #6)
-- ---------------------------------------------------------------------------
do $$
declare
    v_reco_id uuid;
begin
    select id into v_reco_id from public.recommendation_results
    where student_profile_id = 'a0000000-0000-0000-0000-000000000008' limit 1;

    insert into public.recommendation_reasons
        (recommendation_result_id, reason_text, supporting_table, supporting_record_id)
    values
        (v_reco_id, 'Closing merit for this program has historically been below your expected aggregate.',
         'merit_records', 'a0000000-0000-0000-0000-000000000007');
    raise notice 'TEST 6 (supporting_table/supporting_record_id insert): PASS';
exception when others then
    raise notice 'TEST 6 (supporting_table/supporting_record_id insert): FAIL - %', sqlerrm;
end $$;

do $$
begin
    -- pairing check: table without record_id must fail
    insert into public.recommendation_reasons (recommendation_result_id, reason_text, supporting_table)
    select id, 'test', 'merit_records' from public.recommendation_results limit 1;
    raise notice 'TEST 6b (supporting pair check - table without id rejected): FAIL - should have been rejected';
exception when check_violation then
    raise notice 'TEST 6b (supporting pair check - table without id rejected): PASS';
end $$;

-- ---------------------------------------------------------------------------
-- REGRESSION: cross-university consistency trigger still works
-- ---------------------------------------------------------------------------
do $$
begin
    insert into public.universities (id, name, city) values
        ('b0000000-0000-0000-0000-000000000001', 'Other University', 'Karachi');
    insert into public.faculties (id, university_id, name) values
        ('b0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'Faculty of Science');

    insert into public.program_offerings (program_id, campus_id, faculty_id)
    values ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000002',
            'b0000000-0000-0000-0000-000000000002');
    raise notice 'REGRESSION (cross-university consistency): FAIL - should have been blocked';
exception when raise_exception then
    raise notice 'REGRESSION (cross-university consistency): PASS';
end $$;

-- ---------------------------------------------------------------------------
-- REGRESSION: RLS still isolates students from each other
-- ---------------------------------------------------------------------------
insert into auth.users (id, email) values ('33333333-3333-3333-3333-333333333333', 'student.b@test.local');
insert into public.student_profiles (id, user_id, full_name) values
    ('b0000000-0000-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', 'Student B');
insert into public.student_preferences (student_profile_id, preference_type, preferred_city)
values ('b0000000-0000-0000-0000-000000000003', 'general', 'Islamabad');

do $$
begin
    set local role authenticated;
    perform set_config('request.jwt.uid', '11111111-1111-1111-1111-111111111111', true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"student"}}', true);

    if (select count(*) from public.student_preferences) = 2 then
        raise notice 'REGRESSION (RLS isolates students - own row only): FAIL - saw other student''s row';
    else
        raise notice 'REGRESSION (RLS isolates students - own row only): PASS';
    end if;
    reset role;
end $$;

-- ---------------------------------------------------------------------------
-- ROLE MODEL: student isolation on student_profiles (no counselor bypass)
-- ---------------------------------------------------------------------------
do $$
declare
    v_count integer;
begin
    set local role authenticated;
    perform set_config('request.jwt.uid', '11111111-1111-1111-1111-111111111111', true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"student"}}', true);

    select count(*) into v_count from public.student_profiles;
    if v_count = 1 then
        raise notice 'ROLE (student sees only own student_profiles row): PASS';
    else
        raise notice 'ROLE (student sees only own student_profiles row): FAIL - saw % rows', v_count;
    end if;
    reset role;
end $$;

-- Student B's user account, with no counselor/admin claim, must not be able
-- to read or write Student A's profile via any path (there is no assigned-
-- counselor path anymore — this proves that).
do $$
begin
    set local role authenticated;
    perform set_config('request.jwt.uid', '33333333-3333-3333-3333-333333333333', true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"student"}}', true);

    update public.student_profiles
    set full_name = 'Hijacked'
    where id = 'a0000000-0000-0000-0000-000000000008';

    if (select full_name from public.student_profiles where id = 'a0000000-0000-0000-0000-000000000008') = 'Hijacked' then
        raise notice 'ROLE (student cannot write another student''s profile): FAIL - update succeeded';
    else
        raise notice 'ROLE (student cannot write another student''s profile): PASS';
    end if;
    reset role;
end $$;

-- ---------------------------------------------------------------------------
-- ROLE MODEL: admin has full management access
-- ---------------------------------------------------------------------------
do $$
declare
    v_count integer;
begin
    set local role authenticated;
    perform set_config('request.jwt.uid', '22222222-2222-2222-2222-222222222222', true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"admin"}}', true);

    select count(*) into v_count from public.student_profiles;
    if v_count = 2 then
        raise notice 'ROLE (admin sees all student_profiles rows): PASS';
    else
        raise notice 'ROLE (admin sees all student_profiles rows): FAIL - saw % rows (expected 2)', v_count;
    end if;

    update public.student_profiles set full_name = 'Admin Edited' where id = 'b0000000-0000-0000-0000-000000000003';
    if (select full_name from public.student_profiles where id = 'b0000000-0000-0000-0000-000000000003') = 'Admin Edited' then
        raise notice 'ROLE (admin can write any student_profiles row): PASS';
    else
        raise notice 'ROLE (admin can write any student_profiles row): FAIL - update did not apply';
    end if;

    insert into public.universities (name, city) values ('Admin-Created University', 'Islamabad');
    raise notice 'ROLE (admin can write catalog data): PASS';
    reset role;
exception when others then
    raise notice 'ROLE (admin write access): FAIL - %', sqlerrm;
    reset role;
end $$;

-- ---------------------------------------------------------------------------
-- NO COUNSELOR FUNCTIONALITY: schema, functions, and policies confirmed clean
-- ---------------------------------------------------------------------------
do $$
declare
    v_count integer;
begin
    -- No counselor-related column anywhere in the schema.
    select count(*) into v_count
    from information_schema.columns
    where table_schema = 'public' and column_name ilike '%counselor%';
    if v_count = 0 then
        raise notice 'NO-COUNSELOR (no counselor-named column in public schema): PASS';
    else
        raise notice 'NO-COUNSELOR (no counselor-named column in public schema): FAIL - % found', v_count;
    end if;

    -- No counselor-related function.
    select count(*) into v_count
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname ilike '%counselor%';
    if v_count = 0 then
        raise notice 'NO-COUNSELOR (no counselor-named function in public schema): PASS';
    else
        raise notice 'NO-COUNSELOR (no counselor-named function in public schema): FAIL - % found', v_count;
    end if;

    -- No counselor-related RLS policy.
    select count(*) into v_count
    from pg_policies
    where schemaname = 'public' and (policyname ilike '%counselor%' or qual ilike '%counselor%' or with_check ilike '%counselor%');
    if v_count = 0 then
        raise notice 'NO-COUNSELOR (no counselor-referencing RLS policy): PASS';
    else
        raise notice 'NO-COUNSELOR (no counselor-referencing RLS policy): FAIL - % found', v_count;
    end if;
end $$;

-- current_user_role() with an unrecognized 'counselor' claim must NOT grant
-- any special access — it should just fall through as a non-admin caller
-- confined to their own (nonexistent) student_profile.
do $$
declare
    v_count integer;
begin
    set local role authenticated;
    perform set_config('request.jwt.uid', '33333333-3333-3333-3333-333333333333', true);
    perform set_config('request.jwt.claims', '{"app_metadata":{"role":"counselor"}}', true);

    select count(*) into v_count from public.student_profiles;
    if v_count = 1 then
        raise notice 'NO-COUNSELOR (stale ''counselor'' JWT claim grants no special access): PASS';
    else
        raise notice 'NO-COUNSELOR (stale ''counselor'' JWT claim grants no special access): FAIL - saw % rows', v_count;
    end if;
    reset role;
end $$;
