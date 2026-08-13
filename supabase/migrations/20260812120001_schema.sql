-- ============================================================================
-- FUTURE PATHWAYS — DATABASE MIGRATION
-- File: 001_schema.sql
-- Purpose: Core schema — extensions, all 40 tables, constraints, indexes.
-- Source of truth: future-pathways-db-architecture-v3-final.md
-- DO NOT execute against Supabase until reviewed and approved.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. EXTENSIONS
-- ----------------------------------------------------------------------------
create extension if not exists pgcrypto;   -- gen_random_uuid()

-- ----------------------------------------------------------------------------
-- NOTE ON `users` (entity #1 in the architecture)
-- ----------------------------------------------------------------------------
-- Supabase already provides `auth.users` as the authoritative identity table.
-- This migration does NOT create a duplicate `public.users` table. Every
-- reference to "users" in the architecture doc is implemented as a foreign
-- key to auth.users(id). This is flagged explicitly in section F of the
-- deliverable (implementation deviations).

-- ============================================================================
-- 1. INSTITUTIONAL CATALOG
-- ============================================================================

create table public.universities (
    id                  uuid primary key default gen_random_uuid(),
    name                text not null,
    short_name          text,
    city                text,
    province_or_state   text,
    country             text not null default 'Pakistan',
    website_url         text,
    logo_url            text,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    constraint universities_name_unique unique (name)
);

create table public.campuses (
    id              uuid primary key default gen_random_uuid(),
    university_id   uuid not null references public.universities(id) on delete cascade,
    name            text not null,
    city            text,
    address         text,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    constraint campuses_university_name_unique unique (university_id, name)
);
create index campuses_university_id_idx on public.campuses(university_id);

create table public.faculties (
    id              uuid primary key default gen_random_uuid(),
    university_id   uuid not null references public.universities(id) on delete cascade,
    name            text not null,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    constraint faculties_university_name_unique unique (university_id, name)
);
create index faculties_university_id_idx on public.faculties(university_id);

-- career_categories is created here (out of the doc's listed order) because
-- `programs` has a nullable FK to it. See section 4 (Careers) below for the
-- rest of the career_* tables, which is where the architecture groups them.
create table public.career_categories (
    id            uuid primary key default gen_random_uuid(),
    name          text not null,
    description   text,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now(),
    constraint career_categories_name_unique unique (name)
);

create table public.programs (
    -- CANONICAL, university-independent. No FK to universities/campuses/faculties,
    -- direct or indirect. See program_offerings for the pivot. (Architecture v3, A.6 / C.1)
    id                    uuid primary key default gen_random_uuid(),
    name                  text not null,
    level                 text check (level in ('undergraduate','graduate','postgraduate','diploma','certificate')),
    degree_type           text,
    duration_years        numeric(3,1) check (duration_years is null or duration_years > 0),
    career_category_id    uuid references public.career_categories(id) on delete set null,
    description           text,
    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now()
);
create index programs_career_category_id_idx on public.programs(career_category_id);

create table public.program_aliases (
    id            uuid primary key default gen_random_uuid(),
    program_id    uuid not null references public.programs(id) on delete cascade,
    alias         text not null,
    created_at    timestamptz not null default now(),
    constraint program_aliases_program_alias_unique unique (program_id, alias)
);
create index program_aliases_program_id_idx on public.program_aliases(program_id);

create table public.program_offerings (
    -- THE pivot: canonical program × campus × faculty. This is the only
    -- table connecting a canonical program to any university context.
    id              uuid primary key default gen_random_uuid(),
    program_id      uuid not null references public.programs(id) on delete cascade,
    campus_id       uuid not null references public.campuses(id) on delete cascade,
    faculty_id      uuid not null references public.faculties(id) on delete restrict,
    offering_name   text,
    is_active       boolean not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    -- Per C.5: (program_id, campus_id) is the uniqueness key. faculty_id
    -- describes *which* faculty runs it but a campus cannot offer the same
    -- program under two different faculties.
    constraint program_offerings_program_campus_unique unique (program_id, campus_id)
);
create index program_offerings_program_id_idx on public.program_offerings(program_id);
create index program_offerings_campus_id_idx on public.program_offerings(campus_id);
create index program_offerings_faculty_id_idx on public.program_offerings(faculty_id);

-- ============================================================================
-- 2. STUDENT ACADEMIC PROFILE (reference tables + student data)
-- ============================================================================

create table public.qualification_types (
    id            uuid primary key default gen_random_uuid(),
    code          text not null,
    name          text not null,
    level_order   smallint,
    created_at    timestamptz not null default now(),
    constraint qualification_types_code_unique unique (code)
);

create table public.education_boards (
    id            uuid primary key default gen_random_uuid(),
    name          text not null,
    board_type    text check (board_type in ('local','international')),
    created_at    timestamptz not null default now(),
    constraint education_boards_name_unique unique (name)
);

create table public.subjects (
    id            uuid primary key default gen_random_uuid(),
    name          text not null,
    code          text,
    created_at    timestamptz not null default now(),
    constraint subjects_name_unique unique (name),
    constraint subjects_code_unique unique (code)
);

-- student_profiles: identity/profile fields only. No academic marks here.
create table public.student_profiles (
    id                       uuid primary key default gen_random_uuid(),
    user_id                  uuid not null references auth.users(id) on delete cascade,
    full_name                text not null,
    discipline               text,
    section                  text,
    roll_number              text,
    city                     text,
    guardian_name             text,
    guardian_phone            text,
    guardian_email            text,
    created_at               timestamptz not null default now(),
    updated_at               timestamptz not null default now(),
    constraint student_profiles_user_id_unique unique (user_id)
);

create table public.student_academic_records (
    id                       uuid primary key default gen_random_uuid(),
    student_profile_id      uuid not null references public.student_profiles(id) on delete cascade,
    qualification_type_id   uuid not null references public.qualification_types(id) on delete restrict,
    education_board_id      uuid references public.education_boards(id) on delete set null,
    part_number              smallint,
    exam_year                integer,
    obtained_marks           numeric(7,2),
    total_marks              numeric(7,2),
    -- Renamed from result_status per C.2. expected|provisional|final.
    -- obtained_marks/total_marks on 'expected' rows represent the student's
    -- expected marks, not a declared result — no separate expected_marks column.
    completion_status        text not null default 'expected'
                              check (completion_status in ('expected','provisional','final')),
    created_at                timestamptz not null default now(),
    updated_at                timestamptz not null default now(),
    constraint student_academic_records_marks_check
        check (obtained_marks is null or total_marks is null or obtained_marks <= total_marks),
    constraint student_academic_records_marks_nonneg
        check ((obtained_marks is null or obtained_marks >= 0) and (total_marks is null or total_marks >= 0)),
    -- Per C.5. NOTE (flagged, not solved here): Postgres treats NULL as
    -- distinct in unique constraints, so records with part_number IS NULL
    -- are not fully deduplicated by this constraint alone. Documented as a
    -- known minor gap in section F, not treated as an open design question.
    constraint student_academic_records_unique_instance
        unique (student_profile_id, qualification_type_id, part_number, exam_year)
);
create index student_academic_records_student_profile_id_idx on public.student_academic_records(student_profile_id);
create index student_academic_records_qualification_type_id_idx on public.student_academic_records(qualification_type_id);
create index student_academic_records_education_board_id_idx on public.student_academic_records(education_board_id);

create table public.student_academic_subjects (
    id                    uuid primary key default gen_random_uuid(),
    academic_record_id   uuid not null references public.student_academic_records(id) on delete cascade,
    subject_id            uuid not null references public.subjects(id) on delete restrict,
    obtained_marks         numeric(7,2),
    total_marks             numeric(7,2),
    constraint student_academic_subjects_marks_check
        check (obtained_marks is null or total_marks is null or obtained_marks <= total_marks),
    constraint student_academic_subjects_unique unique (academic_record_id, subject_id)
);
create index student_academic_subjects_academic_record_id_idx on public.student_academic_subjects(academic_record_id);
create index student_academic_subjects_subject_id_idx on public.student_academic_subjects(subject_id);

-- admission_tests is created here (ahead of its listed position) because
-- student_test_scores requires it. See section 3 for the rest of admissions data.
create table public.admission_tests (
    id            uuid primary key default gen_random_uuid(),
    name          text not null,
    description   text,
    max_score     numeric(7,2),
    created_at    timestamptz not null default now(),
    constraint admission_tests_name_unique unique (name)
);

create table public.student_test_scores (
    id                    uuid primary key default gen_random_uuid(),
    student_profile_id   uuid not null references public.student_profiles(id) on delete cascade,
    admission_test_id     uuid not null references public.admission_tests(id) on delete restrict,
    -- New in this pass (C.2): differentiates retakes.
    attempt_number         smallint not null default 1 check (attempt_number >= 1),
    score                    numeric(7,2),
    max_score                numeric(7,2),
    test_date                date,
    created_at                timestamptz not null default now(),
    updated_at                timestamptz not null default now(),
    constraint student_test_scores_score_check
        check (score is null or max_score is null or score <= max_score),
    constraint student_test_scores_score_nonneg
        check ((score is null or score >= 0) and (max_score is null or max_score >= 0)),
    constraint student_test_scores_unique unique (student_profile_id, admission_test_id, attempt_number)
);
create index student_test_scores_student_profile_id_idx on public.student_test_scores(student_profile_id);
create index student_test_scores_admission_test_id_idx on public.student_test_scores(admission_test_id);

-- ============================================================================
-- 3. ADMISSIONS DATA
-- ============================================================================

create table public.admission_cycles (
    id              uuid primary key default gen_random_uuid(),
    university_id   uuid not null references public.universities(id) on delete cascade,
    name            text not null,
    year            integer not null,
    start_date      date,
    end_date        date,
    -- Drives the historical-immutability trigger (section 4 of triggers file):
    -- once true, rows in merit_records / fee_records tied to this cycle that
    -- are themselves finalized cannot be silently modified or deleted.
    is_finalized    boolean not null default false,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),
    constraint admission_cycles_university_name_unique unique (university_id, name)
);
create index admission_cycles_university_id_idx on public.admission_cycles(university_id);

create table public.admission_deadlines (
    id                      uuid primary key default gen_random_uuid(),
    -- Nullable per architecture v3 (relationship explicitly tagged
    -- "(nullable)"): some deadlines apply cycle-wide rather than to one
    -- specific program_offering (e.g. a university-wide application close
    -- date). Previously incorrectly NOT NULL in this migration.
    program_offering_id    uuid references public.program_offerings(id) on delete cascade,
    admission_cycle_id      uuid not null references public.admission_cycles(id) on delete cascade,
    deadline_type            text not null,
    deadline_date             timestamptz not null,
    notes                      text,
    created_at                 timestamptz not null default now(),
    updated_at                 timestamptz not null default now()
);
create index admission_deadlines_program_offering_id_idx on public.admission_deadlines(program_offering_id);
create index admission_deadlines_admission_cycle_id_idx on public.admission_deadlines(admission_cycle_id);

create table public.admission_requirements (
    id                      uuid primary key default gen_random_uuid(),
    program_offering_id    uuid not null references public.program_offerings(id) on delete cascade,
    admission_cycle_id      uuid not null references public.admission_cycles(id) on delete cascade,
    qualification_type_id    uuid references public.qualification_types(id) on delete set null,
    -- Different path_labels on the same (offering, cycle) = alternative /
    -- OR eligibility paths. Conditions attached to one path (subjects,
    -- tests, thresholds below) are AND'd together. (Architecture v3 #3)
    path_label                 text not null,
    min_percentage              numeric(5,2) check (min_percentage is null or (min_percentage between 0 and 100)),
    min_obtained_marks           numeric(7,2),
    description                   text,
    created_at                     timestamptz not null default now(),
    updated_at                     timestamptz not null default now(),
    constraint admission_requirements_unique unique (program_offering_id, admission_cycle_id, path_label)
);
create index admission_requirements_program_offering_id_idx on public.admission_requirements(program_offering_id);
create index admission_requirements_admission_cycle_id_idx on public.admission_requirements(admission_cycle_id);
create index admission_requirements_qualification_type_id_idx on public.admission_requirements(qualification_type_id);

create table public.admission_requirement_subjects (
    id                          uuid primary key default gen_random_uuid(),
    admission_requirement_id   uuid not null references public.admission_requirements(id) on delete cascade,
    subject_id                    uuid not null references public.subjects(id) on delete restrict,
    min_marks                      numeric(7,2),
    is_mandatory                    boolean not null default true,
    constraint admission_requirement_subjects_unique unique (admission_requirement_id, subject_id)
);
create index admission_requirement_subjects_requirement_id_idx on public.admission_requirement_subjects(admission_requirement_id);
create index admission_requirement_subjects_subject_id_idx on public.admission_requirement_subjects(subject_id);

create table public.program_required_tests (
    id                          uuid primary key default gen_random_uuid(),
    admission_requirement_id   uuid not null references public.admission_requirements(id) on delete cascade,
    admission_test_id             uuid not null references public.admission_tests(id) on delete restrict,
    min_score                       numeric(7,2),
    weight_percentage                numeric(5,2) check (weight_percentage is null or (weight_percentage between 0 and 100)),
    constraint program_required_tests_unique unique (admission_requirement_id, admission_test_id)
);
create index program_required_tests_requirement_id_idx on public.program_required_tests(admission_requirement_id);
create index program_required_tests_test_id_idx on public.program_required_tests(admission_test_id);

create table public.merit_categories (
    id            uuid primary key default gen_random_uuid(),
    name          text not null,
    description   text,
    constraint merit_categories_name_unique unique (name)
);

create table public.merit_records (
    id                      uuid primary key default gen_random_uuid(),
    program_offering_id    uuid not null references public.program_offerings(id) on delete cascade,
    admission_cycle_id      uuid not null references public.admission_cycles(id) on delete cascade,
    merit_category_id         uuid not null references public.merit_categories(id) on delete restrict,
    round_number                smallint not null default 1 check (round_number >= 1),
    round_label                   text,
    -- 'other' added in this pass (C.3) as an escape hatch for idiosyncratic
    -- merit publications, paired with value_description.
    merit_value_type               text not null
        check (merit_value_type in ('percentage','test_score','combined_score','rank_only','other')),
    closing_value                   numeric(9,3),
    -- Renamed from closing_rank to merit_position to match the architecture's
    -- own terminology (C.3 / Revision 2). Pure naming fix, no behavior change.
    merit_position                    integer,
    value_description                  text,
    seats_available                     integer,
    published_date                       date,
    -- Historical protection: once true, row is immutable (see trigger file).
    is_finalized                          boolean not null default false,
    created_at                              timestamptz not null default now(),
    updated_at                              timestamptz not null default now(),
    constraint merit_records_unique
        unique (program_offering_id, admission_cycle_id, merit_category_id, round_number),
    constraint merit_records_other_requires_description
        check (merit_value_type <> 'other' or value_description is not null)
);
create index merit_records_program_offering_id_idx on public.merit_records(program_offering_id);
create index merit_records_admission_cycle_id_idx on public.merit_records(admission_cycle_id);
create index merit_records_merit_category_id_idx on public.merit_records(merit_category_id);

create table public.fee_records (
    id                      uuid primary key default gen_random_uuid(),
    program_offering_id    uuid not null references public.program_offerings(id) on delete cascade,
    admission_cycle_id      uuid not null references public.admission_cycles(id) on delete cascade,
    fee_type                  text not null,
    amount                      numeric(12,2) not null check (amount >= 0),
    currency                     text not null default 'PKR',
    -- Historical protection: once true, row is immutable (see trigger file).
    is_finalized                  boolean not null default false,
    notes                           text,
    created_at                       timestamptz not null default now(),
    updated_at                       timestamptz not null default now(),
    constraint fee_records_unique unique (program_offering_id, admission_cycle_id, fee_type)
);
create index fee_records_program_offering_id_idx on public.fee_records(program_offering_id);
create index fee_records_admission_cycle_id_idx on public.fee_records(admission_cycle_id);

-- ============================================================================
-- 4. CAREERS
-- ============================================================================
-- (career_categories was created in section 1, ahead of `programs` which
-- references it.)

create table public.career_paths (
    id                      uuid primary key default gen_random_uuid(),
    career_category_id     uuid not null references public.career_categories(id) on delete cascade,
    name                      text not null,
    description                 text,
    constraint career_paths_unique unique (career_category_id, name)
);
create index career_paths_career_category_id_idx on public.career_paths(career_category_id);

create table public.career_path_programs (
    id                  uuid primary key default gen_random_uuid(),
    career_path_id     uuid not null references public.career_paths(id) on delete cascade,
    program_id            uuid not null references public.programs(id) on delete cascade,
    relevance_score         numeric(5,2) check (relevance_score is null or (relevance_score between 0 and 100)),
    constraint career_path_programs_unique unique (career_path_id, program_id)
);
create index career_path_programs_career_path_id_idx on public.career_path_programs(career_path_id);
create index career_path_programs_program_id_idx on public.career_path_programs(program_id);

-- ============================================================================
-- 5. QUESTIONNAIRE
-- ============================================================================

create table public.assessment_questions (
    id                  uuid primary key default gen_random_uuid(),
    question_text       text not null,
    question_type          text not null check (question_type in ('single_choice','multi_choice','scale','text')),
    -- Questionnaire versioning (Architecture v3 #6): old assessment_sessions
    -- remain interpretable after future question edits because sessions
    -- pin the version they were answered under (see assessment_sessions).
    version                   integer not null default 1,
    is_active                   boolean not null default true,
    display_order                 integer,
    created_at                     timestamptz not null default now(),
    updated_at                       timestamptz not null default now()
);

create table public.question_options (
    id                uuid primary key default gen_random_uuid(),
    question_id       uuid not null references public.assessment_questions(id) on delete cascade,
    option_text          text not null,
    option_value            text not null,
    display_order              integer,
    constraint question_options_unique unique (question_id, option_value)
);
create index question_options_question_id_idx on public.question_options(question_id);

create table public.question_rules (
    -- Self-referencing branching/skip logic.
    id                          uuid primary key default gen_random_uuid(),
    question_id                 uuid not null references public.assessment_questions(id) on delete cascade,
    depends_on_question_id     uuid references public.assessment_questions(id) on delete cascade,
    depends_on_option_id          uuid references public.question_options(id) on delete cascade,
    rule_type                       text not null check (rule_type in ('show_if','skip_if','require_if')),
    created_at                        timestamptz not null default now()
);
create index question_rules_question_id_idx on public.question_rules(question_id);
create index question_rules_depends_on_question_id_idx on public.question_rules(depends_on_question_id);
create index question_rules_depends_on_option_id_idx on public.question_rules(depends_on_option_id);

create table public.assessment_sessions (
    id                          uuid primary key default gen_random_uuid(),
    student_profile_id          uuid not null references public.student_profiles(id) on delete cascade,
    -- Pins the questionnaire version this session was answered under.
    questionnaire_version         integer not null,
    status                           text not null default 'in_progress'
        check (status in ('in_progress','completed','abandoned')),
    started_at                         timestamptz not null default now(),
    completed_at                          timestamptz,
    created_at                              timestamptz not null default now(),
    updated_at                                timestamptz not null default now()
);
create index assessment_sessions_student_profile_id_idx on public.assessment_sessions(student_profile_id);

create table public.student_answers (
    id                          uuid primary key default gen_random_uuid(),
    assessment_session_id      uuid not null references public.assessment_sessions(id) on delete cascade,
    question_id                   uuid not null references public.assessment_questions(id) on delete restrict,
    answer_text                      text,
    created_at                         timestamptz not null default now(),
    updated_at                           timestamptz not null default now(),
    constraint student_answers_unique unique (assessment_session_id, question_id)
);
create index student_answers_assessment_session_id_idx on public.student_answers(assessment_session_id);
create index student_answers_question_id_idx on public.student_answers(question_id);

create table public.student_answer_options (
    id                     uuid primary key default gen_random_uuid(),
    student_answer_id      uuid not null references public.student_answers(id) on delete cascade,
    question_option_id        uuid not null references public.question_options(id) on delete restrict,
    constraint student_answer_options_unique unique (student_answer_id, question_option_id)
);
create index student_answer_options_student_answer_id_idx on public.student_answer_options(student_answer_id);
create index student_answer_options_question_option_id_idx on public.student_answer_options(question_option_id);

-- ============================================================================
-- 6. STUDENT-DERIVED DATA
-- ============================================================================

create table public.student_interests (
    id                     uuid primary key default gen_random_uuid(),
    student_profile_id     uuid not null references public.student_profiles(id) on delete cascade,
    career_category_id        uuid references public.career_categories(id) on delete set null,
    interest_label               text not null,
    weight                          numeric(5,2),
    source                            text,
    created_at                         timestamptz not null default now(),
    updated_at                           timestamptz not null default now()
);
create index student_interests_student_profile_id_idx on public.student_interests(student_profile_id);
create index student_interests_career_category_id_idx on public.student_interests(career_category_id);

-- Redesigned (this pass) to actually represent ranked, multi-choice
-- preferences, per architecture v3's "student_profiles 1──N
-- student_preferences" cardinality (which was already 1-N — the previous
-- migration under-delivered on it with a single flat row per student).
--
-- One row per ranked choice (preference_type = 'university' | 'faculty' |
-- 'program_offering', with preference_rank + exactly the matching target
-- FK populated). General, student-level preferences (budget, preferred
-- field, preferred city, free-text notes) live on a single
-- preference_type = 'general' row per student, so they are not duplicated
-- across every ranked-choice row.
create table public.student_preferences (
    id                       uuid primary key default gen_random_uuid(),
    student_profile_id       uuid not null references public.student_profiles(id) on delete cascade,
    preference_type           text not null
        check (preference_type in ('general','university','faculty','program_offering')),
    -- Rank among choices of the same type (1 = most preferred). Null on the
    -- single 'general' row, required on ranked-choice rows.
    preference_rank             smallint check (preference_rank is null or preference_rank >= 1),
    university_id                  uuid references public.universities(id) on delete cascade,
    faculty_id                       uuid references public.faculties(id) on delete cascade,
    program_offering_id                uuid references public.program_offerings(id) on delete cascade,
    -- General-preference fields (only populated on the 'general' row).
    preferred_field                       text,
    preferred_city                          text,
    budget_min                                 numeric(12,2) check (budget_min is null or budget_min >= 0),
    budget_max                                    numeric(12,2) check (budget_max is null or budget_max >= 0),
    preference_notes                                 text,
    created_at                                          timestamptz not null default now(),
    updated_at                                             timestamptz not null default now(),
    constraint student_preferences_budget_check
        check (budget_min is null or budget_max is null or budget_min <= budget_max),
    -- Each row's populated target FK(s) and rank must match its declared
    -- preference_type — prevents e.g. a 'university' row that actually
    -- points at a program_offering, or a ranked row with no rank.
    constraint student_preferences_target_matches_type check (
        (preference_type = 'general'
            and university_id is null and faculty_id is null and program_offering_id is null
            and preference_rank is null)
        or (preference_type = 'university'
            and university_id is not null and faculty_id is null and program_offering_id is null
            and preference_rank is not null)
        or (preference_type = 'faculty'
            and faculty_id is not null and university_id is null and program_offering_id is null
            and preference_rank is not null)
        or (preference_type = 'program_offering'
            and program_offering_id is not null and university_id is null and faculty_id is null
            and preference_rank is not null)
    ),
    constraint student_preferences_rank_unique
        unique (student_profile_id, preference_type, preference_rank)
);
create index student_preferences_student_profile_id_idx on public.student_preferences(student_profile_id);
create index student_preferences_university_id_idx on public.student_preferences(university_id);
create index student_preferences_faculty_id_idx on public.student_preferences(faculty_id);
create index student_preferences_program_offering_id_idx on public.student_preferences(program_offering_id);
-- At most one 'general' row per student (general preferences are singular,
-- not ranked).
create unique index student_preferences_one_general_per_student
    on public.student_preferences(student_profile_id)
    where preference_type = 'general';

-- ============================================================================
-- 7. TRUST / PROVENANCE
-- ============================================================================
-- (created ahead of recommendation_reasons, which references data_sources)

create table public.data_sources (
    id                uuid primary key default gen_random_uuid(),
    university_id     uuid references public.universities(id) on delete set null,
    source_name          text not null,
    source_url              text,
    source_type                text check (source_type in ('official_website','prospectus','manual_entry','third_party','other')),
    created_at                   timestamptz not null default now(),
    updated_at                     timestamptz not null default now()
);
create index data_sources_university_id_idx on public.data_sources(university_id);

create table public.data_verification_records (
    -- Polymorphic reference (table_name + record_id) — cannot be a real FK.
    -- See section F (deviations) for the integrity trade-off and mitigation.
    id                  uuid primary key default gen_random_uuid(),
    data_source_id      uuid not null references public.data_sources(id) on delete cascade,
    table_name              text not null,
    record_id                  uuid not null,
    verified_by                   uuid references auth.users(id) on delete set null,
    verification_status              text not null default 'pending'
        check (verification_status in ('verified','pending','disputed','rejected')),
    verified_at                         timestamptz,
    notes                                  text,
    created_at                                timestamptz not null default now(),
    updated_at                                  timestamptz not null default now()
);
create index data_verification_records_data_source_id_idx on public.data_verification_records(data_source_id);
create index data_verification_records_table_record_idx on public.data_verification_records(table_name, record_id);

-- ============================================================================
-- 8. RECOMMENDATIONS
-- ============================================================================

create table public.recommendation_results (
    id                          uuid primary key default gen_random_uuid(),
    student_profile_id          uuid not null references public.student_profiles(id) on delete cascade,
    -- NOT NULL per architecture v3: the relationship line
    -- "assessment_sessions 1──N recommendation_results" carries no
    -- "(nullable)" tag, so every recommendation must trace back to the
    -- session that produced it. Delete behavior changed from SET NULL to
    -- CASCADE (required, since SET NULL is invalid on a NOT NULL column) —
    -- consistent with recommendation_results being session-derived data.
    assessment_session_id          uuid not null references public.assessment_sessions(id) on delete cascade,
    program_offering_id               uuid not null references public.program_offerings(id) on delete cascade,
    -- Independent per C.4 — any combination is valid (e.g. eligible+reach).
    eligibility_status                   text not null
        check (eligibility_status in ('eligible','conditional','not_eligible','unknown')),
    recommendation_band                     text not null
        check (recommendation_band in ('safe','target','reach')),
    match_score                                numeric(5,2),
    merit_probability                             numeric(5,2) check (merit_probability is null or (merit_probability between 0 and 100)),
    algorithm_version                                text not null,
    generated_at                                        timestamptz not null default now(),
    created_at                                            timestamptz not null default now(),
    updated_at                                              timestamptz not null default now(),
    constraint recommendation_results_unique unique (assessment_session_id, program_offering_id)
);
create index recommendation_results_student_profile_id_idx on public.recommendation_results(student_profile_id);
create index recommendation_results_assessment_session_id_idx on public.recommendation_results(assessment_session_id);
create index recommendation_results_program_offering_id_idx on public.recommendation_results(program_offering_id);

create table public.recommendation_reasons (
    id                          uuid primary key default gen_random_uuid(),
    recommendation_result_id      uuid not null references public.recommendation_results(id) on delete cascade,
    reason_text                       text not null,
    data_source_id                       uuid references public.data_sources(id) on delete set null,
    -- Added this pass: exact supporting-record provenance, mirroring the
    -- data_verification_records polymorphic pattern (table_name +
    -- record_id) already used elsewhere in the architecture. Lets a reason
    -- point to the specific merit_records / fee_records /
    -- admission_requirements / admission_deadlines row that backs it.
    -- Same trade-off as data_verification_records: cannot be a real FK
    -- since it spans multiple possible target tables.
    supporting_table                        text,
    supporting_record_id                       uuid,
    created_at                              timestamptz not null default now(),
    constraint recommendation_reasons_supporting_pair_check
        check (
            (supporting_table is null and supporting_record_id is null)
            or (supporting_table is not null and supporting_record_id is not null)
        )
);
create index recommendation_reasons_recommendation_result_id_idx on public.recommendation_reasons(recommendation_result_id);
create index recommendation_reasons_data_source_id_idx on public.recommendation_reasons(data_source_id);
create index recommendation_reasons_supporting_record_idx on public.recommendation_reasons(supporting_table, supporting_record_id);

-- ============================================================================
-- 9. SAVED ITEMS
-- ============================================================================

create table public.saved_universities (
    id                     uuid primary key default gen_random_uuid(),
    student_profile_id     uuid not null references public.student_profiles(id) on delete cascade,
    university_id              uuid not null references public.universities(id) on delete cascade,
    created_at                    timestamptz not null default now(),
    constraint saved_universities_unique unique (student_profile_id, university_id)
);
create index saved_universities_student_profile_id_idx on public.saved_universities(student_profile_id);
create index saved_universities_university_id_idx on public.saved_universities(university_id);

create table public.saved_programs (
    id                     uuid primary key default gen_random_uuid(),
    student_profile_id     uuid not null references public.student_profiles(id) on delete cascade,
    program_offering_id       uuid not null references public.program_offerings(id) on delete cascade,
    created_at                   timestamptz not null default now(),
    constraint saved_programs_unique unique (student_profile_id, program_offering_id)
);
create index saved_programs_student_profile_id_idx on public.saved_programs(student_profile_id);
create index saved_programs_program_offering_id_idx on public.saved_programs(program_offering_id);

-- ============================================================================
-- END OF 001_schema.sql — 40 tables created (see MIGRATION_NOTES.md, section A
-- for the count reconciliation: `users` is implemented as auth.users, not a
-- new table, so table count here is 39 + auth.users).
-- ============================================================================
