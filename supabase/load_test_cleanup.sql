-- =========================================================
-- Cleanup for load_test_seed_100_students.sql
--
-- Deleting from auth.users cascades through app_users ->
-- students -> future_pathways -> the three preference tables
-- (all ON DELETE CASCADE per future_pathways_schema.sql), so
-- this one statement removes every trace of the load-test data
-- in one shot. Real accounts are untouched -- the email domain
-- match is exact and load-test accounts all use
-- @loadtest.rah.internal, which no real account would ever have.
--
-- Run this after you're done load-testing.
-- =========================================================

delete from auth.users
where email like '%@loadtest.rah.internal';

-- Verify it's actually gone:
select count(*) as remaining_loadtest_students
from public.students s
join auth.users u on u.id = s.id
where u.email like '%@loadtest.rah.internal';
-- should return 0
