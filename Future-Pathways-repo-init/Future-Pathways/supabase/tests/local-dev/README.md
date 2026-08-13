# Local-dev test harness (not part of the migration)

These three files are **not** migration files and must never be applied to
the real Supabase project or placed in `supabase/migrations/`. They exist
only to let the migration be exercised against a bare local PostgreSQL
instance that doesn't have Supabase's platform-managed `auth` schema,
roles, or grants.

| File | Purpose |
|---|---|
| `000_auth_stub.sql` | Mimics the parts of Supabase's `auth` schema this migration depends on (`auth.users`, `auth.uid()`, `auth.jwt()`). Real Supabase already provides all of this natively. |
| `999_test_harness_grants.sql` | Replicates the role grants (`authenticated`, `anon`, `service_role`) Supabase provisions automatically at the platform level, so RLS can be exercised locally. |
| `run_tests.sql` | The 24-check functional test suite: schema creation, the cross-university consistency trigger, the finalized-record immutability trigger, and RLS behavior for student / admin roles. |

## Local run order (against a bare Postgres instance only)

```
000_auth_stub.sql
<supabase/migrations/*.sql, in order>
999_test_harness_grants.sql
run_tests.sql
```

## Why these aren't Supabase CLI migrations

`supabase start` already gives you a full local stack with a real `auth`
schema and real role grants — you would only reach for these stub files if
testing the raw SQL against plain `postgres` outside the Supabase CLI
(e.g. in CI, or the environment this migration was originally validated in).
When using `supabase start` / `supabase db reset` locally, skip this folder
entirely and just let the CLI apply `supabase/migrations/` as-is.
