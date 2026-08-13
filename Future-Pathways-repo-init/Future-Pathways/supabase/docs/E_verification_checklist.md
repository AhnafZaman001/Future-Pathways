# E. Verification / Test Checklist

## What has already been verified (this session)

The full migration (`001_schema.sql` → `002_functions_triggers.sql` → `003_rls_policies.sql`) was run end-to-end against a real, local PostgreSQL 16 instance with a minimal stub of Supabase's `auth` schema (`auth.users`, `auth.uid()`, `auth.jwt()` reading from session GUCs, plus the `authenticated`/`anon`/`service_role` roles). This is not the same as Supabase's actual environment, but it does prove the SQL is syntactically valid and that the logic behaves as intended, not just that it "looks right."

| # | Test | Result |
|---|---|---|
| 1 | `001_schema.sql` applies cleanly, 0 errors | ✅ Pass — 39 tables created in `public` (+ `auth.users` = 40 entities) |
| 2 | `002_functions_triggers.sql` applies cleanly, 0 errors | ✅ Pass |
| 3 | `003_rls_policies.sql` applies cleanly, 0 errors | ✅ Pass |
| 4 | `program_offerings` insert with campus/faculty in the **same** university | ✅ Pass — succeeds |
| 5 | `program_offerings` insert with campus/faculty in **different** universities | ✅ Pass — blocked by trigger with a clear error message |
| 6 | Non-finalized `merit_records` row can be updated | ✅ Pass |
| 7 | Finalized (`is_finalized = true`) `merit_records` row: `UPDATE` | ✅ Pass — blocked by trigger |
| 8 | Finalized `merit_records` row: `DELETE` | ✅ Pass — blocked by trigger |
| 9 | Student A, authenticated, selects `student_preferences` | ✅ Pass — sees only their own row (1 of 2 total rows) |
| 10 | Student A explicitly filters for Student B's `student_preferences` row | ✅ Pass — returns 0 rows (RLS silently filters, doesn't error) |
| 11 | Student A reads catalog data (`universities`) | ✅ Pass — full read access as expected |
| 12 | Student A attempts to `INSERT` into `universities` | ✅ Pass — blocked by RLS (`insufficient_privilege`) |
| 13 | ~~Counselor assigned to Student A selects Student A's `student_profiles` row~~ | **SUPERSEDED** — counselor role removed in a later revision (see "Revision — counselor role removed" below) |
| 14 | ~~Same counselor selects Student B's (unassigned) `student_profiles` row~~ | **SUPERSEDED** — see below |
| 15 | ~~Same counselor attempts `UPDATE` on Student A's profile (read-only intent)~~ | **SUPERSEDED** — see below |
| 16 | Admin inserts a new `universities` row | ✅ Pass — succeeds |
| 17 | Admin selects `student_profiles` across all students | ✅ Pass — sees both students |

## What still needs to happen before / during real deployment

These require the actual Supabase project and cannot be fully verified in a local stub:

1. **Run against a real Supabase project (staging), not just local Postgres.**
   - Confirm `auth.uid()` / `auth.jwt()` behave identically to the stub (they should — the stub mirrors Supabase's documented implementation, but Supabase-specific extensions or config could differ).
   - Confirm `pgcrypto` is available (Supabase enables it by default; verify anyway).

2. **Set up `app_metadata.role` for real users.**
   - `role` must be set via the Supabase Admin API / service-role key when provisioning admin accounts (students can be left to default to `'student'` per `current_user_role()`'s `coalesce`).
   - Only `student` and `admin` are supported roles — there is no counselor workflow.

3. **Confirm `service_role` bypasses RLS as expected** for any backend job that writes `recommendation_results`, finalizes `merit_records`/`fee_records`, etc. — this is Supabase's documented default behavior but should be confirmed with an actual service-role-authenticated call before relying on it.

4. **Load-bearing data test**: insert a realistic multi-university, multi-program, multi-offering dataset (even a handful of rows) and confirm:
   - A canonical program can be offered by two different universities via two `program_offerings` rows.
   - Multiple alternative `admission_requirements` paths for one offering/cycle are all retrievable and distinguishable by `path_label`.
   - A student with two `student_test_scores` rows for the same test (`attempt_number` 1 and 2) both persist correctly.

5. **Cascade/delete-behavior review with real data volumes.**
   - Confirm `ON DELETE CASCADE` from `student_profiles` doesn't unexpectedly cascade-delete data that should be retained (e.g., `recommendation_results` referencing a deleted student — currently cascades; confirm this is the desired retention policy, not just the default).
   - Confirm `ON DELETE RESTRICT` on reference tables (`qualification_types`, `subjects`, `admission_tests`, `merit_categories`, faculties via `program_offerings`) behaves as expected — i.e., you cannot delete a subject that's still referenced by academic records without first handling the dependents.

6. **Performance review once real data volumes exist** — indexes were added on all foreign keys as a baseline, but query patterns from the actual recommendation engine (once built) may surface a need for additional composite indexes (e.g., on `recommendation_results (student_profile_id, recommendation_band)`).

7. **RLS policy review by a second person** before going live — RLS bugs are silent-by-default (queries return fewer rows, not errors), so an independent review of `003_rls_policies.sql` against the intended access model is worth doing even though this session's tests passed.

## Revision — six audit corrections applied and verified

The six corrections identified in the latest schema conformance audit were applied to `001_schema.sql` / `002_functions_triggers.sql` and re-verified end-to-end against a fresh local PostgreSQL 16 instance (auth stub + harness grants, same method as above). All prior 17 tests were re-run implicitly by re-applying `001`→`003` cleanly; the following 15 new/targeted tests (`tests/run_tests.sql`) were added for the corrections themselves:

| # | Test | Result |
|---|---|---|
| 1 | `merit_records.merit_position` accepts inserts | ✅ Pass |
| 1b | `merit_records.closing_rank` no longer exists | ✅ Pass |
| 2 | `admission_deadlines` insert with `program_offering_id = null` (cycle-wide deadline) | ✅ Pass |
| 3 | `recommendation_results` insert with `assessment_session_id = null` is rejected | ✅ Pass |
| 3b | `recommendation_results` insert with a valid `assessment_session_id` succeeds | ✅ Pass |
| 4 | `student_preferences`: one `general` row + multiple ranked rows (`university`, `program_offering`) insert together | ✅ Pass |
| 4b | Ranked row with mismatched target FK (e.g. `preference_type='university'` but `program_offering_id` also set) rejected | ✅ Pass |
| 4c | Ranked row (`preference_type='university'`) with no `preference_rank` rejected | ✅ Pass |
| 4d | Second `general`-type row for the same student rejected | ✅ Pass |
| 5a | `fee_records` row updatable while its `admission_cycle` is not finalized | ✅ Pass |
| 5b | `fee_records` row (not itself finalized) blocked from `UPDATE` once its `admission_cycle.is_finalized = true` | ✅ Pass |
| 5c | Same row blocked from `DELETE` under the same condition | ✅ Pass |
| 6 | `recommendation_reasons` insert with `supporting_table` + `supporting_record_id` succeeds | ✅ Pass |
| 6b | `recommendation_reasons` insert with `supporting_table` set but `supporting_record_id` null rejected | ✅ Pass |
| — | Regression: cross-university consistency trigger still blocks mismatched campus/faculty | ✅ Pass |
| — | Regression: RLS still isolates one student's `student_preferences` from another's | ✅ Pass |

**15/15 new tests passed. 0 errors applying `001`→`003` in order.**

### Still needs to happen before / during real deployment (in addition to items 1–7 above)

8. Re-run the full RLS suite (student/admin, items 4–17 from the original checklist, minus the now-superseded counselor items 13–15) specifically against the redesigned `student_preferences` shape and the new `recommendation_reasons` columns, against real Supabase — the local re-run above only exercised the two regression checks listed, not the full original 17-item matrix.

## Revision — counselor role removed (product-requirements correction)

Product confirmed Future Pathways has no counselor workflow — it is student self-service only. Removed: `student_profiles.assigned_counselor_id` (column + its index), `public.is_counselor()`, the counselor branch in `public.can_access_student_profile()`, the counselor clause in the `student_profiles_select` RLS policy, and every counselor reference in comments/docs. Supported roles are now exactly `student` and `admin`.

The full migration (`001`→`003`) was rebuilt from a dropped database and re-applied end-to-end — **0 errors** — then the complete local test suite (`tests/run_tests.sql`, now 24 checks: the 15 correction tests + 2 prior regressions + 4 new role-model tests + 3 new no-counselor-functionality checks) was run fresh:

| # | Test | Result |
|---|---|---|
| 1, 1b | `merit_position` / `closing_rank` removed | ✅ Pass |
| 2 | Nullable `admission_deadlines.program_offering_id` | ✅ Pass |
| 3, 3b | Required `recommendation_results.assessment_session_id` | ✅ Pass |
| 4, 4b, 4c, 4d | Ranked `student_preferences` (insert, mismatch rejected, missing rank rejected, duplicate general rejected) | ✅ Pass |
| 5a, 5b, 5c | Cycle-level finalization protection on `fee_records` | ✅ Pass |
| 6, 6b | `recommendation_reasons` supporting-record provenance | ✅ Pass |
| — | Regression: cross-university consistency trigger | ✅ Pass |
| — | Regression: RLS isolates one student's `student_preferences` from another's | ✅ Pass |
| — | **New:** student sees only their own `student_profiles` row | ✅ Pass |
| — | **New:** a student cannot write another student's `student_profiles` row (no counselor bypass exists) | ✅ Pass |
| — | **New:** admin sees all `student_profiles` rows | ✅ Pass |
| — | **New:** admin can write any student's profile and write catalog data | ✅ Pass |
| — | **New:** no column anywhere in `public` matches `%counselor%` | ✅ Pass |
| — | **New:** no function anywhere in `public` matches `%counselor%` | ✅ Pass |
| — | **New:** no RLS policy (name, `USING`, or `WITH CHECK`) matches `%counselor%` | ✅ Pass |
| — | **New:** a stale `'counselor'` value in a JWT's `app_metadata.role` grants no special access (falls through as an ordinary non-admin caller, confined to their own profile) | ✅ Pass |

**24/24 tests passed. 0 errors applying `001`→`003` in order. No counselor functionality remains anywhere in the schema, functions, policies, or introduced replacement.**

## Explicitly out of scope for this phase (per your instructions)

- No seed data (universities, programs, merit, questionnaire content) was inserted beyond what was needed for the tests above, and all test data was in a disposable local database, not Supabase.
- No frontend integration was built or tested.
- Nothing in this migration has been executed against the actual Supabase project — it is provided for review only.
