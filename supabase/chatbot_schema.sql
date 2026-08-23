-- =========================================================
-- chatbot_schema.sql
--
-- Backs the counsellor-facing chat assistant (js/fp-chat-assistant.js
-- + supabase/functions/chat-assistant). Groq's free tier is shared
-- across the WHOLE app, not per-user -- one enthusiastic counsellor
-- with no cap could burn the daily quota for everyone else. This
-- table is what the edge function checks before making each call.
--
-- Deliberately has NO RLS policies for `authenticated` -- the client
-- never touches this table directly. Only the edge function (using
-- the service_role key, which bypasses RLS entirely) reads/writes it.
-- RLS is still enabled so that if the anon/authenticated grants were
-- ever accidentally added later, the table fails closed rather than
-- open.
-- =========================================================

create table if not exists public.chatbot_requests (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists idx_chatbot_requests_user_time
  on public.chatbot_requests(user_id, created_at);

alter table public.chatbot_requests enable row level security;
-- No policies created -- authenticated/anon get zero access by
-- default once RLS is on. Only service_role (used by the edge
-- function) can read/write this table.

-- Housekeeping: rows older than 7 days aren't needed for rate
-- limiting (windows here are 1h/6h) and would otherwise grow
-- forever. Run this occasionally (e.g. paste into the SQL Editor
-- every few months), or wire it to pg_cron if you want it automatic.
-- delete from public.chatbot_requests where created_at < now() - interval '7 days';
