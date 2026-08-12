-- TEST HARNESS ONLY. Not part of the migration. Supabase provisions these
-- grants automatically at the platform level; a bare local Postgres instance
-- does not, so we replicate them here purely to exercise RLS locally.
grant usage on schema public to authenticated, anon, service_role;
grant all on all tables in schema public to authenticated;
grant all on all tables in schema public to service_role;
grant select on all tables in schema public to anon;
grant usage, select on all sequences in schema public to authenticated, service_role;
grant execute on all functions in schema public to authenticated, anon, service_role;
grant usage on schema auth to authenticated, anon, service_role;
grant select on auth.users to authenticated, service_role;
grant execute on all functions in schema auth to authenticated, anon, service_role;
alter default privileges in schema public grant all on tables to authenticated;
