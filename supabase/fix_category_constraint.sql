-- =========================================================
-- Fix: widen institutes.category check constraint to allow
-- medical subtypes (nums / private / other) in addition to
-- engineering / medical. Dental colleges are merged into the
-- 'medical' category (not a separate subtype).
--
-- Run this ONCE in the Supabase SQL Editor, then run
-- future_pathways_seed.sql (it's safe to re-run — it starts
-- with TRUNCATE).
-- =========================================================

alter table public.institutes
  drop constraint if exists institutes_category_check;

alter table public.institutes
  add constraint institutes_category_check
  check (category in ('engineering','medical','nums','private','other'));
