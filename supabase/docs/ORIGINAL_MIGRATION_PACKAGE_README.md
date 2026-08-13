# Future Pathways — Database Migration (V3 → PostgreSQL/Supabase)

Source of truth: `future-pathways-db-architecture-v3-final.md` (approved). This migration implements it as-is; it does not redesign anything.

**Status: awaiting review. Not executed against Supabase.**

## Files

| File | Contents |
|---|---|
| `001_schema.sql` | Extensions + all 40 entities (39 tables in `public`, plus `auth.users`) with columns, constraints, and indexes |
| `002_functions_triggers.sql` | `updated_at` maintenance, cross-university consistency enforcement, finalized-record immutability, RLS helper functions |
| `003_rls_policies.sql` | Row Level Security for every table |
| `D_constraints_explanation.md` | Deliverable **D** — explanation of important constraints, organized by the architecture's 8 key decisions |
| `E_verification_checklist.md` | Deliverable **E** — what was tested this session (against a live local Postgres instance) and what still needs testing against real Supabase |
| `F_implementation_deviations.md` | Deliverable **F** — every unavoidable implementation deviation from the approved architecture, flagged individually |

## Execution order

Run in this order, in a single migration or as three sequential ones:

```
001_schema.sql
002_functions_triggers.sql
003_rls_policies.sql
```

Each depends on the one before it (functions/triggers reference tables from `001`; RLS policies reference helper functions from `002`).

## What this migration does NOT do (per your instructions)

- Does not redesign the approved V3 architecture.
- Does not build any frontend.
- Does not seed universities, programs, merit data, fee data, or questionnaire content.
- Has not been executed against the actual Supabase project.

## Headline implementation notes (see `F_implementation_deviations.md` for full detail)

1. **`users` = `auth.users`.** No duplicate `public.users` table was created; `student_profiles.user_id` references Supabase's `auth.users(id)` directly. This is why `001_schema.sql` creates 39 tables, not 40 — the 40th entity is Supabase-managed.
2. **Role-based access uses JWT `app_metadata.role`**, not a roles table — this follows the recommendation already in the architecture doc's section E.
3. **Role model: `student` and `admin` only.** Future Pathways has no counselor workflow — it's a student self-service product. Students access only their own data; admins have management access.

## Verified this session

The full migration was applied to a real local PostgreSQL 16 instance (with a Supabase `auth` schema stub) and exercised with functional tests covering: schema creation, the cross-university consistency trigger, the finalized-record immutability trigger, and RLS behavior for student / admin roles. Full detail and remaining pre-production checks are in `E_verification_checklist.md`.

## Next step

Please review, in particular:
- `F_implementation_deviations.md` items 1–3 (identity/role model) — these are the deviations most likely to need your or ChatGPT's sign-off before this goes further.
- The RLS policy set in `003_rls_policies.sql` against the intended access model.

Once approved, this can be run against a real Supabase staging project (see `E_verification_checklist.md` item 1 for what to re-verify there specifically).
