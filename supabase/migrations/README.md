# Migrations

These three files are the approved, locally-tested (24/24 checks) migration
implementation of `future-pathways-db-architecture-v3-final.md`. Content is
byte-for-byte identical to the reviewed migration deliverable — only the
filenames changed, to satisfy the Supabase CLI's required
`<timestamp>_<name>.sql` convention (the CLI uses the timestamp prefix to
determine apply order and to track which migrations have already run).

| File | Was | Contents |
|---|---|---|
| `20260812120001_schema.sql` | `001_schema.sql` | Extensions + all 39 `public` tables (40th entity, `users`, is Supabase's `auth.users`) with columns, constraints, indexes |
| `20260812120002_functions_triggers.sql` | `002_functions_triggers.sql` | `updated_at` maintenance, cross-university consistency trigger, finalized-record immutability trigger, RLS helper functions |
| `20260812120003_rls_policies.sql` | `003_rls_policies.sql` | Row Level Security policies for every table |

Order matters and is enforced by the timestamps: `002` depends on tables from
`001`; `003` depends on helper functions from `002`.

**Status: not yet applied to the remote Supabase project.** See the repo root
`README.md` for the commands that will do this, and `supabase/docs/` for the
full review material (constraints explanation, verification checklist,
implementation deviations) before applying.
