# F. Unavoidable Implementation Deviations from the Approved V3 Architecture

None of these change the approved data model. They are implementation-level decisions that the architecture document either left open (explicitly, in section E) or didn't address because it's architecture-only and these are migration-phase concerns. Flagged per your working rule rather than decided silently.

## 1. `users` implemented as `auth.users`, not a new `public.users` table

The architecture lists `users` as entity #1 with a `users 1──1 student_profiles` relationship. Supabase already provides `auth.users` as the platform's authoritative identity/auth table. Creating a second, parallel `public.users` table would either duplicate `auth.users` (sync burden, drift risk) or sit unused. This migration implements the relationship as `student_profiles.user_id → auth.users(id)` directly.

**Effect on entity count**: 39 tables were created in `public`, not 40 — `auth.users` is the 40th entity, managed by Supabase rather than this migration. If this isn't the intended interpretation, it's a one-line change to add a `public.users` table instead — flagging now rather than assuming.

## 2. No dedicated roles table — role carried in JWT `app_metadata`

Section E of the architecture doc already flags this as an open implementation choice and recommends JWT custom claims over `SECURITY DEFINER` helper functions querying a roles table — this migration follows that recommendation. Supported roles are `student` and `admin`; nothing in the schema itself declares role membership — that's carried entirely in `app_metadata.role`, set by whoever provisions the account (must go through the Supabase Admin API / service-role key, not client-side).

**Implication**: if the product later needs richer role data (e.g., multiple admins with different permission levels), a real `user_roles`/`staff_profiles` table will likely be needed. Not built now since it's outside the approved 40 entities.

**Update (this revision):** Product confirmed Future Pathways has no counselor workflow — it's student self-service only. `student_profiles.assigned_counselor_id` has been removed, `public.is_counselor()` has been removed, and `public.can_access_student_profile()` no longer has a counselor branch. Only `student` and `admin` are supported roles anywhere in this migration now.

## 3. `data_verification_records`'s polymorphic reference is not FK-enforced

`table_name` + `record_id` (architecture's own description: "polymorphic: table_name + record_id") cannot be a real foreign key, because a single column pair needs to reference rows across many different tables. The migration implements this exactly as specified but the trade-off is real: the database cannot guarantee `record_id` actually exists in the table named by `table_name`. Mitigations available if this becomes a real problem post-launch (not implemented now, since it would mean deviating further from the literal spec):
- An application-layer check before insert.
- A periodic integrity-check job that flags orphaned verification records.

**Update:** `recommendation_reasons.supporting_table` / `supporting_record_id`, added per audit Correction #6, deliberately reuses this exact pattern (and inherits the same trade-off) so a recommendation reason can point at the specific merit/fee/requirement/deadline row backing it. A `check` constraint enforces that the pair is either both null or both set, but not that `supporting_record_id` actually exists in `supporting_table` — same mitigation options as above apply.

## 4. `recommendation_results` / `recommendation_reasons` writable only by `admin` under RLS

These tables are system-generated (by whatever computes eligibility/merit-probability/recommendation bands). The architecture doesn't say who is allowed to write them, so this migration takes the conservative default: students get read-only access to their own results; only `admin`-role sessions can write. In practice, the actual recommendation engine will likely run as a backend job using the Supabase `service_role` key, which bypasses RLS entirely — the `admin`-only policy here is a safety net for any direct client-side write attempt, not the primary write path. Worth confirming this matches the intended architecture (a service-role backend job) once that component is built.

## 5. AND/OR eligibility-path logic is representable, not enforced, by the schema

Per C.3 of the source architecture: different `path_label` rows under one `admission_requirements` group represent alternative (OR) paths; everything hung off one `admission_requirement_id` is implicitly AND'd. The schema makes this shape representable (grouping by `path_label`) but does not itself evaluate eligibility — that logic belongs in the (not-yet-built) recommendation engine. Noting this so it isn't assumed to be a database-level guarantee.

## 6. `student_academic_records` NULL-handling gap, left open per the architecture's own note

Already called out explicitly in the source document (C.5): the unique constraint `(student_profile_id, qualification_type_id, part_number, exam_year)` doesn't fully deduplicate rows where `part_number IS NULL`, because Postgres treats `NULL` as distinct in unique constraints. The architecture document itself says this is "acceptable for now, flagged rather than solved." This migration implements it exactly as specified — flagging again here per your working rule, not because it's a new discovery.

## 7. Historical-record immutability trigger has no built-in "reopen" path

`block_finalized_record_mutation()` blocks *all* `UPDATE`/`DELETE` once `is_finalized = true` (on the row itself or, as of this revision, on its `admission_cycle`), with no exception carved out for "just flipping `is_finalized` back to `false`." This was a deliberate choice (reopening a finalized record should be a rare, visible, explicit action), but it does mean the *only* way to correct a finalized merit or fee record is to disable the trigger temporarily (a privileged, auditable operation) rather than there being a supported "unfinalize" flow through normal RLS-governed writes. Flagging in case the product actually wants a controlled unfinalize path (e.g., admin-only `UPDATE` that's allowed to flip `is_finalized` and nothing else) — that would be a small, additive change to the trigger function if wanted.

## 8. No `created_by` / audit-trail columns

Consistent with section E's own note ("Provenance of first data entry — deliberately left out to avoid column sprawl... can be added later as a non-breaking nullable column"). Not added in this migration. `created_at`/`updated_at` exist everywhere applicable; `data_verification_records.verified_by` is the one place an actor is tracked, because the architecture explicitly calls for verification tracking.

---

**None of the above required redesigning any entity, relationship, or the 40-entity count as approved.** They are the implementation-phase decisions the architecture document itself anticipated needing (section E) or gaps it already flagged and deferred (C.5), plus one small identity/access decision (`auth.users`) that was necessary to make the schema executable against Supabase but wasn't pinned down at the architecture level. The counselor role and its supporting column/function/policy were removed in this revision per a direct product-requirements correction, not an architecture-level open question.
