-- ============================================================================
-- FUTURE PATHWAYS — DATABASE MIGRATION
-- File: 003_rls_policies.sql
-- Purpose: Row Level Security for every table.
-- Depends on: 001_schema.sql, 002_functions_triggers.sql
--
-- Model:
--   - Students may only access their own student-owned data.
--   - Admins have full management access.
--   - Catalog/reference data (universities, programs, merit, fees, etc.) is
--     readable by any authenticated user and writable only by admins.
--   - Role is resolved via public.current_user_role() (JWT app_metadata).
--   - No counselor role or workflow — Future Pathways is student
--     self-service only. Supported roles: 'student' | 'admin'.
--
-- DO NOT execute against Supabase until reviewed and approved.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. STUDENT-OWNED DATA
-- ----------------------------------------------------------------------------

-- ---- student_profiles --------------------------------------------------
alter table public.student_profiles enable row level security;

create policy student_profiles_select on public.student_profiles
    for select to authenticated
    using (
        user_id = auth.uid()
        or public.is_admin()
    );

create policy student_profiles_insert on public.student_profiles
    for insert to authenticated
    with check (user_id = auth.uid() or public.is_admin());

create policy student_profiles_update on public.student_profiles
    for update to authenticated
    using (user_id = auth.uid() or public.is_admin())
    with check (user_id = auth.uid() or public.is_admin());

create policy student_profiles_delete on public.student_profiles
    for delete to authenticated
    using (public.is_admin());

-- ---- student_academic_records ------------------------------------------
alter table public.student_academic_records enable row level security;

create policy student_academic_records_select on public.student_academic_records
    for select to authenticated
    using (public.can_access_student_profile(student_profile_id));

create policy student_academic_records_insert on public.student_academic_records
    for insert to authenticated
    with check (student_profile_id = public.current_student_profile_id() or public.is_admin());

create policy student_academic_records_update on public.student_academic_records
    for update to authenticated
    using (student_profile_id = public.current_student_profile_id() or public.is_admin())
    with check (student_profile_id = public.current_student_profile_id() or public.is_admin());

create policy student_academic_records_delete on public.student_academic_records
    for delete to authenticated
    using (student_profile_id = public.current_student_profile_id() or public.is_admin());

-- ---- student_academic_subjects (owned via academic_record_id) ----------
alter table public.student_academic_subjects enable row level security;

create policy student_academic_subjects_select on public.student_academic_subjects
    for select to authenticated
    using (
        exists (
            select 1 from public.student_academic_records sar
            where sar.id = academic_record_id
              and public.can_access_student_profile(sar.student_profile_id)
        )
    );

create policy student_academic_subjects_write on public.student_academic_subjects
    for all to authenticated
    using (
        exists (
            select 1 from public.student_academic_records sar
            where sar.id = academic_record_id
              and (sar.student_profile_id = public.current_student_profile_id() or public.is_admin())
        )
    )
    with check (
        exists (
            select 1 from public.student_academic_records sar
            where sar.id = academic_record_id
              and (sar.student_profile_id = public.current_student_profile_id() or public.is_admin())
        )
    );

-- ---- student_test_scores -------------------------------------------------
alter table public.student_test_scores enable row level security;

create policy student_test_scores_select on public.student_test_scores
    for select to authenticated
    using (public.can_access_student_profile(student_profile_id));

create policy student_test_scores_write on public.student_test_scores
    for all to authenticated
    using (student_profile_id = public.current_student_profile_id() or public.is_admin())
    with check (student_profile_id = public.current_student_profile_id() or public.is_admin());

-- ---- assessment_sessions --------------------------------------------------
alter table public.assessment_sessions enable row level security;

create policy assessment_sessions_select on public.assessment_sessions
    for select to authenticated
    using (public.can_access_student_profile(student_profile_id));

create policy assessment_sessions_write on public.assessment_sessions
    for all to authenticated
    using (student_profile_id = public.current_student_profile_id() or public.is_admin())
    with check (student_profile_id = public.current_student_profile_id() or public.is_admin());

-- ---- student_answers (owned via assessment_session_id) --------------------
alter table public.student_answers enable row level security;

create policy student_answers_select on public.student_answers
    for select to authenticated
    using (
        exists (
            select 1 from public.assessment_sessions s
            where s.id = assessment_session_id
              and public.can_access_student_profile(s.student_profile_id)
        )
    );

create policy student_answers_write on public.student_answers
    for all to authenticated
    using (
        exists (
            select 1 from public.assessment_sessions s
            where s.id = assessment_session_id
              and (s.student_profile_id = public.current_student_profile_id() or public.is_admin())
        )
    )
    with check (
        exists (
            select 1 from public.assessment_sessions s
            where s.id = assessment_session_id
              and (s.student_profile_id = public.current_student_profile_id() or public.is_admin())
        )
    );

-- ---- student_answer_options (owned via student_answer_id) -----------------
alter table public.student_answer_options enable row level security;

create policy student_answer_options_select on public.student_answer_options
    for select to authenticated
    using (
        exists (
            select 1 from public.student_answers a
            join public.assessment_sessions s on s.id = a.assessment_session_id
            where a.id = student_answer_id
              and public.can_access_student_profile(s.student_profile_id)
        )
    );

create policy student_answer_options_write on public.student_answer_options
    for all to authenticated
    using (
        exists (
            select 1 from public.student_answers a
            join public.assessment_sessions s on s.id = a.assessment_session_id
            where a.id = student_answer_id
              and (s.student_profile_id = public.current_student_profile_id() or public.is_admin())
        )
    )
    with check (
        exists (
            select 1 from public.student_answers a
            join public.assessment_sessions s on s.id = a.assessment_session_id
            where a.id = student_answer_id
              and (s.student_profile_id = public.current_student_profile_id() or public.is_admin())
        )
    );

-- ---- student_interests -----------------------------------------------------
alter table public.student_interests enable row level security;

create policy student_interests_select on public.student_interests
    for select to authenticated
    using (public.can_access_student_profile(student_profile_id));

create policy student_interests_write on public.student_interests
    for all to authenticated
    using (student_profile_id = public.current_student_profile_id() or public.is_admin())
    with check (student_profile_id = public.current_student_profile_id() or public.is_admin());

-- ---- student_preferences ----------------------------------------------------
alter table public.student_preferences enable row level security;

create policy student_preferences_select on public.student_preferences
    for select to authenticated
    using (public.can_access_student_profile(student_profile_id));

create policy student_preferences_write on public.student_preferences
    for all to authenticated
    using (student_profile_id = public.current_student_profile_id() or public.is_admin())
    with check (student_profile_id = public.current_student_profile_id() or public.is_admin());

-- ---- saved_universities -------------------------------------------------------
alter table public.saved_universities enable row level security;

create policy saved_universities_select on public.saved_universities
    for select to authenticated
    using (public.can_access_student_profile(student_profile_id));

create policy saved_universities_write on public.saved_universities
    for all to authenticated
    using (student_profile_id = public.current_student_profile_id() or public.is_admin())
    with check (student_profile_id = public.current_student_profile_id() or public.is_admin());

-- ---- saved_programs -------------------------------------------------------------
alter table public.saved_programs enable row level security;

create policy saved_programs_select on public.saved_programs
    for select to authenticated
    using (public.can_access_student_profile(student_profile_id));

create policy saved_programs_write on public.saved_programs
    for all to authenticated
    using (student_profile_id = public.current_student_profile_id() or public.is_admin())
    with check (student_profile_id = public.current_student_profile_id() or public.is_admin());

-- ---- recommendation_results (system-generated; students read-only) ---------------
alter table public.recommendation_results enable row level security;

create policy recommendation_results_select on public.recommendation_results
    for select to authenticated
    using (public.can_access_student_profile(student_profile_id));

create policy recommendation_results_write on public.recommendation_results
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

-- ---- recommendation_reasons (owned via recommendation_result_id) -----------------
alter table public.recommendation_reasons enable row level security;

create policy recommendation_reasons_select on public.recommendation_reasons
    for select to authenticated
    using (
        exists (
            select 1 from public.recommendation_results r
            where r.id = recommendation_result_id
              and public.can_access_student_profile(r.student_profile_id)
        )
    );

create policy recommendation_reasons_write on public.recommendation_reasons
    for all to authenticated
    using (public.is_admin())
    with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- 2. CATALOG / REFERENCE DATA — readable by any authenticated user,
--    writable only by admins. (Not student-owned; no per-row ownership.)
-- ----------------------------------------------------------------------------

do $$
declare
    t text;
    catalog_tables text[] := array[
        'universities','campuses','faculties',
        'programs','program_aliases','program_offerings',
        'qualification_types','education_boards','subjects',
        'admission_tests','admission_cycles','admission_deadlines',
        'admission_requirements','admission_requirement_subjects','program_required_tests',
        'merit_categories','merit_records','fee_records',
        'career_categories','career_paths','career_path_programs',
        'assessment_questions','question_options','question_rules',
        'data_sources','data_verification_records'
    ];
begin
    foreach t in array catalog_tables loop
        execute format('alter table public.%I enable row level security;', t);

        execute format(
            'create policy %I on public.%I for select to authenticated using (true);',
            t || '_select', t
        );

        execute format(
            'create policy %I on public.%I for insert to authenticated with check (public.is_admin());',
            t || '_insert', t
        );

        execute format(
            'create policy %I on public.%I for update to authenticated using (public.is_admin()) with check (public.is_admin());',
            t || '_update', t
        );

        execute format(
            'create policy %I on public.%I for delete to authenticated using (public.is_admin());',
            t || '_delete', t
        );
    end loop;
end $$;

-- ============================================================================
-- END OF 003_rls_policies.sql
--
-- Note: service_role (used by trusted backend/recommendation-engine jobs)
-- bypasses RLS by default in Supabase and is not given explicit policies
-- here. Any client-facing write to system-generated tables (recommendation_*,
-- merit_records, fee_records, etc.) that isn't coming from an admin user
-- must go through a service-role backend process, not directly from the
-- client with a user JWT.
-- ============================================================================
