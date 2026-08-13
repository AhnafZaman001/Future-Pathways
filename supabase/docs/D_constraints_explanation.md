# D. Explanation of Important Constraints

Reference for the migration in `001_schema.sql` / `002_functions_triggers.sql` / `003_rls_policies.sql`. Organized by the eight architectural decisions in the source document.

## 1. Canonical program model

- `programs` has **no foreign key** to `universities`, `campuses`, or `faculties` — checked by construction (no such column exists).
- `program_offerings` carries `program_id` (→ `programs`), `campus_id` (→ `campuses`), `faculty_id` (→ `faculties`, `NOT NULL` per C.1).
- **Cross-university consistency** (`campus_id`'s university must equal `faculty_id`'s university) cannot be expressed as a plain FK or `CHECK` constraint, because it requires comparing values looked up from two other tables. Implemented as a `BEFORE INSERT OR UPDATE` trigger (`enforce_program_offering_university_consistency`) that raises an exception on mismatch. Verified against both a same-university insert (succeeds) and a cross-university insert (blocked) during testing.
- Uniqueness is `(program_id, campus_id)`, not `(program_id, campus_id, faculty_id)` — a campus cannot offer the same canonical program under two different faculties, matching C.5's note that faculty describes *which* faculty runs the offering, not an additional dimension of uniqueness.

## 2. Student academic model

- `completion_status` (renamed from `result_status`) is constrained to `expected | provisional | final`. No separate "expected marks" columns — `obtained_marks`/`total_marks` are reused, with `completion_status` giving them meaning.
- `student_academic_records` uniqueness is `(student_profile_id, qualification_type_id, part_number, exam_year)`. **Known gap, deliberately not solved here** (per the architecture doc's own flag in C.5): Postgres treats `NULL` as distinct in unique constraints, so two records for the same student/qualification with `part_number IS NULL` are not deduplicated by this constraint alone. A partial unique index could close this later if it becomes a real problem; not added now since the source document explicitly calls this a minor edge case rather than something to solve in this pass.
- `student_test_scores.attempt_number` (`smallint`, default `1`) plus the unique constraint `(student_profile_id, admission_test_id, attempt_number)` allows multiple attempts at the same test (e.g., two MDCAT sittings) without collision.
- Marks fields have non-negativity and `obtained <= total` `CHECK` constraints at both the record level and the subject level.

## 3. Admission requirements

- `admission_requirements.path_label` plus the unique constraint `(program_offering_id, admission_cycle_id, path_label)` is what makes multiple **alternative (OR)** eligibility paths for the same offering/cycle representable — each row is one path.
- Everything hung off a single `admission_requirement_id` (subject requirements via `admission_requirement_subjects`, test requirements via `program_required_tests`, plus the requirement's own `min_percentage`/`min_obtained_marks`) is implicitly **AND**'d, because all of it must be satisfied to satisfy *that* path.
- This is an architectural pattern enforced by the application layer reading requirement rows grouped by `path_label`, not a database constraint — the schema makes it representable, not automatically evaluated. Flagged in section F.

## 4. Merit

- `merit_value_type` supports `percentage | test_score | combined_score | rank_only | other`, with `closing_value` (numeric) and `merit_position` (integer) as separate columns rather than forcing every metric into one field.
- `value_description` is required (`CHECK` constraint) whenever `merit_value_type = 'other'` — the escape hatch always carries an explanation, it can't be silently empty.
- `round_number` + `round_label` support multiple merit lists per cycle; uniqueness is `(program_offering_id, admission_cycle_id, merit_category_id, round_number)`.
- **Historical protection**: `merit_records.is_finalized` drives a trigger (`block_finalized_record_mutation`) that raises on any `UPDATE` or `DELETE` once `is_finalized = true`. Verified in testing: a non-finalized record updates freely; the same record, once finalized, rejects both an `UPDATE` and a `DELETE` with a clear error. To correct a finalized record, an operator must first explicitly set `is_finalized = false` — a deliberate, auditable action, not something the trigger does automatically. The same mechanism is applied to `fee_records`.

## 5. Recommendations

- `eligibility_status` (`eligible | conditional | not_eligible | unknown`) and `recommendation_band` (`safe | target | reach`) are two independent, separately-constrained columns on `recommendation_results` — no `CHECK` constraint ties them together, so every combination (including `eligible` + `reach`) is valid, matching C.4.
- `match_score`, `merit_probability`, and `algorithm_version` are retained as separate columns, unchanged in meaning from the architecture doc.
- `recommendation_results` and `recommendation_reasons` are **not writable by students** under RLS — only `admin` (i.e., in practice, a backend job authenticated as admin, or more commonly the `service_role` key which bypasses RLS entirely) can insert/update/delete them. Students get read-only access to their own results. This reflects that recommendations are system-generated, not student-editable data — see section F for the operational implication.

## 6. Questionnaire

- `assessment_questions.version` and `assessment_sessions.questionnaire_version` implement the versioning requirement: a session pins the version of the questionnaire it was answered under, so future edits to `assessment_questions`/`question_options` don't retroactively change the meaning of old sessions' answers.
- `question_rules` is self-referencing (`depends_on_question_id → assessment_questions.id`) to support branching/skip logic between questions.

## 7. Data provenance

- `data_verification_records` uses a **polymorphic reference** (`table_name text`, `record_id uuid`) rather than a real foreign key, because a single verification-tracking table needs to point at rows in many different fact tables (university details, merit records, fee records, deadlines, etc.). This is a deliberate trade-off flagged in section F: the database cannot guarantee `record_id` actually exists in `table_name` at the FK level.

## 8. Security (RLS)

- Role (`student | admin`) is read from the JWT's `app_metadata.role` claim via `public.current_user_role()`, per the architecture document's own recommendation in section E toward JWT custom claims over a separate roles table. Future Pathways has no counselor workflow — students access only their own data, admins have management access.
- `public.can_access_student_profile(id)` is the single helper used everywhere a table needs to check "does the caller own this student's data, or are they an admin" — kept as one function so the access rule is defined once, not reimplemented per table.
- Catalog/reference tables (universities, programs, merit, fees, etc.) are readable by any authenticated user and writable only by admins — there's no per-row ownership concept for this data.
- All policies were exercised against a live Postgres instance with simulated JWTs for a student, an unrelated student, and an admin — see section E (verification checklist) for the specific scenarios covered.
