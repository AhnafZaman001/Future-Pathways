# Future Pathways — Database Architecture, Final Revision (v3)

Status: architecture-only. No SQL, no migrations, no Supabase table creation, no frontend, no seed data.

---

## A. Final Entity List

**Identity & people**
1. `users`
2. `student_profiles` — identity/profile fields only (name-adjacent info, discipline, section, roll number, city, guardian info, assigned counselor). No academic marks live here — see group 3.

**Institutional catalog**
3. `universities`
4. `campuses`
5. `faculties`
6. `programs` — canonical, university-independent
7. `program_offerings` — the pivot: program × campus × faculty
8. `program_aliases`

**Student academic profile**
9. `qualification_types` — reference (Matric/O-Level tier, FSc/A-Level tier, etc.)
10. `education_boards` — reference (BISE Lahore, Federal Board, Cambridge, IBCC...)
11. `subjects` — reference, shared with eligibility requirements
12. `student_academic_records` — one row per qualification instance per student
13. `student_academic_subjects` — subject-level marks within an academic record
14. `student_test_scores` — entry-test attempts, referencing `admission_tests`

**Admissions data**
15. `admission_cycles`
16. `admission_deadlines`
17. `admission_tests`
18. `admission_requirements` — supports multiple alternative eligibility paths
19. `admission_requirement_subjects`
20. `program_required_tests`
21. `merit_categories`
22. `merit_records`
23. `fee_records`

**Careers**
24. `career_categories`
25. `career_paths`
26. `career_path_programs`

**Questionnaire**
27. `assessment_questions`
28. `question_options`
29. `question_rules`
30. `assessment_sessions`
31. `student_answers`
32. `student_answer_options`

**Student-derived data**
33. `student_interests`
34. `student_preferences`

**Recommendations**
35. `recommendation_results` — carries `eligibility_status`, `recommendation_band`, `match_score`, `algorithm_version`
36. `recommendation_reasons`

**Saved items**
37. `saved_universities`
38. `saved_programs`

**Trust / provenance**
39. `data_sources`
40. `data_verification_records`

No tables added or removed in this revision — this pass corrected relationships and fields on existing entities only, per your instruction to make only the six listed corrections.

---

## B. Final Relationships

```
universities 1──N campuses
universities 1──N faculties
universities 1──N admission_cycles
universities 1──N data_sources (nullable)

programs 1──N program_aliases
programs N:1 career_categories (nullable)
programs 1──N program_offerings        ← the ONLY link between a canonical program
                                           and any university context

program_offerings N:1 campuses
program_offerings N:1 faculties        ← university-specific context lives HERE, not on programs
program_offerings 1──N admission_requirements N:1 admission_cycles
program_offerings 1──N merit_records N:1 admission_cycles
program_offerings 1──N fee_records N:1 admission_cycles
program_offerings 1──N admission_deadlines (nullable) N:1 admission_cycles
program_offerings 1──N saved_programs
program_offerings 1──N recommendation_results

admission_requirements N:1 qualification_types (nullable)
admission_requirements 1──N admission_requirement_subjects N:1 subjects
admission_requirements 1──N program_required_tests N:1 admission_tests

merit_records N:1 merit_categories

career_categories 1──N career_paths
career_paths N:N programs (via career_path_programs)

qualification_types 1──N student_academic_records
education_boards 1──N student_academic_records (nullable)
student_academic_records 1──N student_academic_subjects N:1 subjects

users 1──1 student_profiles
student_profiles 1──N student_academic_records
student_profiles 1──N student_test_scores N:1 admission_tests
student_profiles 1──N assessment_sessions
student_profiles 1──N student_interests
student_profiles 1──N student_preferences
student_profiles 1──N saved_universities N:1 universities
student_profiles 1──N saved_programs
student_profiles 1──N recommendation_results

assessment_sessions 1──N student_answers N:N question_options (via student_answer_options)
assessment_sessions 1──N recommendation_results 1──N recommendation_reasons N:1 data_sources (nullable)

assessment_questions 1──N question_options
assessment_questions 1──N question_rules (self-referencing)

data_sources 1──N data_verification_records (polymorphic: table_name + record_id)
```

**The canonical-program relationship, stated plainly, since it's the crux of correction #1:**
`programs` has no FK to `universities`, `campuses`, or `faculties` — none, direct or indirect. The *only* thing connecting "BS Computer Science" (canonical) to "COMSATS, Lahore campus, Faculty of Computing" is a single row in `program_offerings`: `{ program_id: BS-CS, campus_id: COMSATS-Lahore, faculty_id: Faculty-of-Computing }`. A second university offering the same canonical BS Computer Science just adds a second `program_offerings` row pointing at the same `program_id` and a different `campus_id`/`faculty_id`. This was actually already the shape after Revision 2 — see C.1 below for what, specifically, changed in this pass versus what was confirmed as already correct.

---

## C. Changes Made in This Revision

### C.1 — Canonical program model: confirmed, tightened, not re-architected

Checking Revision 2 against this instruction: `programs.faculty_id` was **already removed** in Revision 2 (see that document's section C.1) — `program_offerings` already carried `faculty_id`. So there is no lingering direct dependency to remove here; the structure you described (canonical program → program_offering → campus/faculty/university) is what Revision 2 already established.

One real tightening made in this pass: **`program_offerings.faculty_id` changes from nullable to `NOT NULL`.** Revision 2 left it nullable ("some programs aren't organized under a faculty"). Your worked example — BS CS / COMSATS / Lahore / Faculty of Computing / program_offering — treats faculty as a required part of what makes an offering meaningful, so this pass makes that structurally required rather than optional. If a genuine faculty-less offering ever shows up (some smaller institutes don't organize by faculty), that's a real exception to handle explicitly later, not a default to leave open now.

No other change to this part of the schema — `universities → campuses`, `universities → faculties`, `programs → program_offerings ← campuses/faculties` is the final shape.

### C.2 — Student academic data: two field-level fixes, structure otherwise confirmed

The normalized structure (`qualification_types`, `education_boards`, `subjects`, `student_academic_records`, `student_academic_subjects`, `student_test_scores`) was introduced in Revision 2 and already covers Matric/O-Level/FSc/A-Level/other, Part I/Part II, subject combinations, and board/exam system. Two corrections in this pass:

- **`result_status` renamed to `completion_status`**, values `expected | provisional | final`, to match your terminology exactly and make explicit that `obtained_marks`/`total_marks` on a record with `completion_status = 'expected'` represent the student's *expected* marks, not a declared result. This avoids a separate redundant "expected_marks" column duplicating the marks fields.
- **`student_test_scores` gains `attempt_number` (smallint, not null, default 1)** — Revision 2's test-result table didn't account for retakes. A student who sat MDCAT twice now gets two rows differentiated by `attempt_number`, and `(student_profile_id, admission_test_id, attempt_number)` becomes a unique constraint (see C.5).

`student_profiles` remains identity/profile-only, as instructed — no academic marks were reintroduced there.

### C.3 — Merit model: one addition for genuinely uncategorizable metrics

Revision 2 already added `merit_value_type` (`percentage | test_score | combined_score | rank_only`) and `merit_position` to stop assuming every closing merit is a percentage, plus `round_number`/`round_label` for multi-list cycles. This pass adds:

- **`merit_value_type` gains an `other` option**, paired with a new nullable `value_description` (text) field on `merit_records` — for the small number of universities that publish merit in some idiosyncratic way that doesn't fit percentage/test_score/combined_score/rank_only. Rather than keep expanding the enum indefinitely as odd cases turn up, `other` + a free-text description is the escape hatch.

Historical separation by admission cycle, program offering, and category is unchanged from Revision 2 (and was correct there).

### C.4 — Recommendation model: eligibility_status and recommendation_band as two independent enums

This is a genuine correction, not just a confirmation. Revision 2 had `eligibility_status` (`eligible | not_eligible | partially_eligible | unknown`) and `classification` (`safe | target | reach`) as two separate columns — the *concept* of independence was already there, but your exact vocabulary differs:

- **`classification` renamed to `recommendation_band`** — values `safe | target | reach`, unchanged in meaning, renamed to match your terminology.
- **`eligibility_status`'s `partially_eligible` renamed to `conditional`** — values now `eligible | conditional | not_eligible | unknown`, matching your list exactly.

Both columns remain fully independent on `recommendation_results`, so `eligible + reach`, `eligible + safe`, `conditional + target`, etc. are all valid, representable combinations — exactly as you described. `match_score` and `algorithm_version` are unchanged.

### C.5 — Data integrity: FK and unique-constraint pass after the above changes

| Table | Unique constraint | Notes |
|---|---|---|
| `program_offerings` | `(program_id, campus_id)` | Unchanged. `faculty_id` describes *which* faculty runs this offering but isn't part of what makes the offering unique — a campus doesn't offer the same program under two different faculties. |
| `admission_requirements` | `(program_offering_id, admission_cycle_id, path_label)` | Unchanged from Revision 2. |
| `admission_requirement_subjects` | `(admission_requirement_id, subject_id)` | Unchanged. |
| `merit_records` | `(program_offering_id, admission_cycle_id, merit_category_id, round_number)` | Unchanged — still the mechanism that guarantees a new year/round can never collide with or overwrite an old one. |
| `student_academic_records` | `(student_profile_id, qualification_type_id, part_number, exam_year)` | New in this pass. Note: Postgres treats `NULL` as distinct in unique constraints, so qualifications without a Part split (`part_number` null) aren't fully deduplicated at the DB level by this constraint alone — acceptable for now, flagged rather than solved with a partial index, since it's a minor edge case. |
| `student_academic_subjects` | `(academic_record_id, subject_id)` | Unchanged. |
| `student_test_scores` | `(student_profile_id, admission_test_id, attempt_number)` | New in this pass, enabling correction C.2. |
| `recommendation_results` | `(session_id, program_offering_id)` | Unchanged. |

FK review — nothing else changed shape; the one FK that changed nullability is `program_offerings.faculty_id` (nullable → `NOT NULL`, per C.1). The cross-university consistency rule (`program_offerings.campus_id`'s university must equal `program_offerings.faculty_id`'s university) still cannot be expressed as a plain FK and still needs a trigger at migration time — this was flagged in Revision 2 and remains an implementation detail for the migration phase, not an open design question.

---

## D. Final ERD (text form)

```
universities
 ├─< campuses
 ├─< faculties
 ├─< admission_cycles
 └─< data_sources (nullable)

programs
 ├─< program_aliases
 ├─>─ career_categories (nullable)
 └─< program_offerings ─>─ campuses
                        └─>─ faculties (NOT NULL)

program_offerings
 ├─< admission_requirements ─>─ admission_cycles
 │                           └─>─ qualification_types (nullable)
 │                           ├─< admission_requirement_subjects ─>─ subjects
 │                           └─< program_required_tests ─>─ admission_tests
 ├─< merit_records ─>─ admission_cycles
 │                  └─>─ merit_categories
 ├─< fee_records ─>─ admission_cycles
 ├─< admission_deadlines (nullable) ─>─ admission_cycles
 ├─< saved_programs
 └─< recommendation_results

career_categories ─< career_paths ─>─<─ programs (career_path_programs)

qualification_types ─< student_academic_records
education_boards (nullable) ─< student_academic_records
student_academic_records ─< student_academic_subjects ─>─ subjects

users ─1─ student_profiles
student_profiles
 ├─< student_academic_records
 ├─< student_test_scores ─>─ admission_tests
 ├─< assessment_sessions
 ├─< student_interests
 ├─< student_preferences
 ├─< saved_universities ─>─ universities
 ├─< saved_programs
 └─< recommendation_results

assessment_sessions
 ├─< student_answers ─>─<─ question_options (student_answer_options)
 └─< recommendation_results ─< recommendation_reasons ─>─ data_sources (nullable)

assessment_questions ─< question_options
assessment_questions ─< question_rules (self-referencing)

data_sources ─< data_verification_records (polymorphic: table_name + record_id)

recommendation_results fields of note:
  eligibility_status:      eligible | conditional | not_eligible | unknown
  recommendation_band:     safe | target | reach
  match_score:             numeric
  algorithm_version:       text
  (both enums independent — any combination is valid)
```

---

## E. Remaining Architectural Concerns

No major concerns. The items below are implementation-phase decisions, not open design gaps — none require another schema revision:

- Cross-university consistency trigger for `program_offerings` (campus's university = faculty's university) — build this trigger during migration; the rule is already decided, only the implementation is pending.
- RLS mechanism (`SECURITY DEFINER` helper functions vs. JWT custom claims) — a migration-phase implementation choice, previously flagged with a recommendation toward JWT claims; doesn't affect the schema itself.
- Provenance of first data entry (`created_by`) — deliberately left out to avoid column sprawl across five fact tables; can be added later as a non-breaking nullable column if needed post-launch.

**Architecture ready for migration approval.**
