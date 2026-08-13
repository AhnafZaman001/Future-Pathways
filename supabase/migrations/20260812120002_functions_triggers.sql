-- ============================================================================
-- FUTURE PATHWAYS — DATABASE MIGRATION
-- File: 002_functions_triggers.sql
-- Purpose: updated_at maintenance, cross-university consistency enforcement,
--          historical-record immutability, RLS helper functions.
-- Depends on: 001_schema.sql
-- DO NOT execute against Supabase until reviewed and approved.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. updated_at maintenance
-- ----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

-- Applied to every table that has an updated_at column.
do $$
declare
    t text;
    tables text[] := array[
        'universities','campuses','faculties','programs','program_offerings',
        'qualification_types',
        'student_profiles','student_academic_records','student_test_scores',
        'admission_cycles','admission_deadlines','admission_requirements',
        'merit_records','fee_records',
        'assessment_questions','assessment_sessions','student_answers',
        'student_interests','student_preferences',
        'data_sources','data_verification_records',
        'recommendation_results'
    ];
begin
    foreach t in array tables loop
        execute format(
            'create trigger set_updated_at before update on public.%I
             for each row execute function public.set_updated_at();', t
        );
    end loop;
end $$;

-- ----------------------------------------------------------------------------
-- 2. Cross-university consistency: program_offerings.campus_id and
--    program_offerings.faculty_id must belong to the same university.
--    This cannot be expressed as a plain FK/CHECK because it requires
--    comparing values across two other tables. (Architecture v3, C.5 / E)
-- ----------------------------------------------------------------------------
create or replace function public.enforce_program_offering_university_consistency()
returns trigger
language plpgsql
as $$
declare
    campus_university_id   uuid;
    faculty_university_id  uuid;
begin
    select university_id into campus_university_id
    from public.campuses where id = new.campus_id;

    select university_id into faculty_university_id
    from public.faculties where id = new.faculty_id;

    if campus_university_id is null then
        raise exception 'program_offerings: campus_id % does not exist', new.campus_id;
    end if;

    if faculty_university_id is null then
        raise exception 'program_offerings: faculty_id % does not exist', new.faculty_id;
    end if;

    if campus_university_id <> faculty_university_id then
        raise exception
            'program_offerings: campus (university %) and faculty (university %) belong to different universities',
            campus_university_id, faculty_university_id;
    end if;

    return new;
end;
$$;

create trigger enforce_program_offering_university_consistency
    before insert or update of campus_id, faculty_id on public.program_offerings
    for each row execute function public.enforce_program_offering_university_consistency();

-- ----------------------------------------------------------------------------
-- 3. Historical immutability: finalized merit_records / fee_records rows
--    must not be silently modified or deleted. A row is protected if EITHER
--    its own is_finalized flag is true, OR the admission_cycle it belongs
--    to is finalized (admission_cycles.is_finalized) — finalizing a whole
--    cycle locks every merit/fee row under it without having to flip each
--    row's flag individually. UPDATE and DELETE are blocked at the database
--    level in either case. To correct a row protected only at the row
--    level, an operator flips that row's is_finalized back to false first;
--    to correct a row protected at the cycle level, the cycle itself must
--    be unfinalized. This trigger does not special-case either transition,
--    by design: reopening should be rare and visible, not implicit.
--    (Previously this trigger only checked the row's own is_finalized flag;
--    admission_cycles.is_finalized existed on the table but was never
--    consulted. Fixed this pass.)
-- ----------------------------------------------------------------------------
create or replace function public.block_finalized_record_mutation()
returns trigger
language plpgsql
as $$
declare
    cycle_finalized boolean;
begin
    select is_finalized into cycle_finalized
    from public.admission_cycles
    where id = old.admission_cycle_id;

    if tg_op = 'DELETE' then
        if old.is_finalized or coalesce(cycle_finalized, false) then
            raise exception '% record % is finalized (row or admission cycle) and cannot be deleted', tg_table_name, old.id;
        end if;
        return old;
    end if;

    -- UPDATE
    if old.is_finalized or coalesce(cycle_finalized, false) then
        raise exception '% record % is finalized (row or admission cycle) and cannot be modified', tg_table_name, old.id;
    end if;

    return new;
end;
$$;

create trigger block_finalized_merit_record_mutation
    before update or delete on public.merit_records
    for each row execute function public.block_finalized_record_mutation();

create trigger block_finalized_fee_record_mutation
    before update or delete on public.fee_records
    for each row execute function public.block_finalized_record_mutation();

-- ----------------------------------------------------------------------------
-- 4. RLS helper functions
-- ----------------------------------------------------------------------------
-- Role is read from JWT app_metadata (custom claim), per the architecture's
-- own recommendation in section E ("RLS mechanism ... previously flagged
-- with a recommendation toward JWT claims"). No separate roles table exists
-- in the approved 40-entity architecture, so app_metadata.role is the
-- carrier for 'student' | 'admin' — Future Pathways has no counselor
-- workflow, so only these two roles are supported. See section F for the
-- operational implication (role must be set via service-role calls, e.g.
-- Supabase Admin API, when provisioning admin accounts).

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
    select coalesce(auth.jwt() -> 'app_metadata' ->> 'role', 'student');
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select public.current_user_role() = 'admin';
$$;

-- Resolves the calling user's own student_profiles.id, if any.
create or replace function public.current_student_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
    select id from public.student_profiles where user_id = auth.uid();
$$;

-- True if the given student_profile belongs to the caller, or the caller is
-- an admin. (No counselor path — Future Pathways is student-self-service
-- only; students access exclusively their own data, admins manage all.)
create or replace function public.can_access_student_profile(target_student_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select
        public.is_admin()
        or exists (
            select 1 from public.student_profiles sp
            where sp.id = target_student_profile_id
              and sp.user_id = auth.uid()
        );
$$;

-- ============================================================================
-- END OF 002_functions_triggers.sql
-- ============================================================================
