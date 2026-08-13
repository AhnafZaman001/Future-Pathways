-- ============================================================================
-- LOCAL TEST STUB ONLY — mimics the parts of Supabase's `auth` schema that
-- this migration depends on (auth.users, auth.uid(), auth.jwt()).
-- Not part of the migration deliverable; not run against real Supabase,
-- which already provides all of this natively.
-- ============================================================================
create schema if not exists auth;

create table if not exists auth.users (
    id uuid primary key default gen_random_uuid(),
    email text
);

-- Session-local variables let tests set "the current caller" per-transaction.
create or replace function auth.uid() returns uuid
language sql stable
as $$
    select nullif(current_setting('request.jwt.uid', true), '')::uuid;
$$;

create or replace function auth.jwt() returns jsonb
language sql stable
as $$
    select nullif(current_setting('request.jwt.claims', true), '')::jsonb;
$$;
