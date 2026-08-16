# PROGRESS.md — ground truth as of this commit

This file exists so a new Claude session (or you, months later) doesn't
have to reconstruct the state of this project from chat history. If
anything here conflicts with what a chat says, **trust this file and
the actual repo/database — re-verify by cloning fresh and checking
Supabase directly.**

## What this project is

"Rah" — a Pakistani university/college counselling tool. Two things
live in one repo:

1. **The quick calculator** (`index.html`) — matric + FSc Part 1 marks
   in, provisional merit score + suggested universities out. The
   original prototype; still live, now pulls institutes from Supabase
   instead of a hardcoded array.
2. **Future Pathways** (`pathways.html` + `admin.html`) — the real
   product: digitizes an actual paper counselling form used by a
   school. Multi-step form, ranked institute/faculty preferences,
   draft autosave, one-submission-per-student, counsellor/admin
   evaluation panel.

Both require login (`login.html`) — Supabase Auth, email/password only,
**no self-signup**. Accounts are created manually in the Supabase
dashboard (Authentication → Add user), mirroring how a separate project
called AXIOM does auth. New signups (if any) default to role='student'
via a database trigger.

A third thing, added most recently: **the Merit & Entry Test Guide**
(`merit.html`) — a searchable database of exactly how ~30 institutes
calculate admission merit (weightages, entry tests, sourced). See the
README's "Merit & Entry Test Guide" section for the full breakdown.

## No build step, anywhere

Every page is plain HTML + vanilla JS loaded via `<script src="...">`
tags, no bundler, no npm install. Supabase client comes from a CDN
(`@supabase/supabase-js@2` via jsdelivr). This is deliberate — keep it
that way unless there's a real reason to add a build step.

## Supabase setup order (run once, in this order, in SQL Editor)

1. `supabase/schema.sql` — the original `student_submissions` table
   (used only by the old quick-calculator's save-to-DB feature)
2. `supabase/future_pathways_schema.sql` — the real schema: `students`
   / `app_users`, `institutes`, `fp_faculties`, `career_options`,
   `program_options`, `future_pathways`, preference tables,
   `office_evaluations`, RLS, the `on_auth_user_created` trigger
3. `supabase/future_pathways_seed.sql` — institutes/faculties/careers
   master data (safe to re-run, starts with TRUNCATE ... CASCADE)
4. `supabase/fix_category_constraint.sql` — widens
   `institutes.category` to allow `nums`/`private`/`other` subtypes
   (needed before step 3's data will insert cleanly — **if starting
   from scratch, run this before step 3**, not after)
5. `supabase/merit_formulas_schema.sql` — the merit guide table, RLS
6. `supabase/merit_formulas_seed_data.sql` — 84 formula rows
7. `select public.link_merit_formulas_to_institutes();` — one-time
   call to link merit rows to institute rows by name match

`supabase/restore_auth_policies.sql` is a **patch**, not part of the
normal setup order — it exists because auth/RLS was toggled to open
access at one point while debugging, then reverted. Only relevant if
you're diagnosing why RLS looks wrong.

**A real gotcha that already bit this project once:** an RLS policy
alone does NOT expose a table to Supabase's Data API. You also need an
explicit Postgres `grant ... to authenticated` (or `anon`, depending on
the table). Every schema file in this repo already includes the grants
— if you add a new table by hand, don't forget this or every
insert/select will silently fail with no obvious error.

## Naming quirks worth knowing before you get confused

- The faculties table is `fp_faculties`, not `faculties` — renamed to
  avoid colliding with an unrelated legacy table.
- `institutes.category` values are `engineering`, `medical`, `nums`,
  `private`, `other` — dental colleges are folded into `medical`, not
  a separate category.
- Student role table is `app_users` (referenced in `fp-client.js`),
  though some SQL comments/older text may still say `profiles` — that
  was an earlier name during initial scaffolding and was renamed.
- `Fazal Medical College` (not "Fazaia") is the correct name — this
  was deliberately fixed to match the source data.
- The staff/role-check RLS helper is `public.current_role()` — it
  returns the role as **text** (`'student'` / `'counsellor'` /
  `'admin'`), used as `public.current_role() in ('counsellor','admin')`
  inside policies. It is **not** called `is_staff()` and does **not**
  return a boolean — an earlier merit-formulas schema draft used
  `is_staff()` by mistake (copied from a different, discarded draft of
  this project) and failed with `function public.is_staff() does not
  exist` when run. Match the real function name and signature exactly
  before writing new RLS policies.
- Master-data read policies (`institutes`, `fp_faculties`,
  `program_options`, `career_options`, `merit_formulas`) grant `select`
  to **both** `anon` and `authenticated` — so these lists can render
  before login — while `insert`/`update`/`delete` are granted to
  `authenticated` only and further gated by `current_role()` in RLS.
  Match this exact anon/authenticated split for any new master-data
  table; don't default to `authenticated`-only for reads.

## Known intentional gaps (not bugs)

- `Counsellor.MERIT_FEATURE_ENABLED = false` in `js/data.js` — the
  quick calculator's own merit-based Strong/Competitive/Unlikely
  scoring is OFF on purpose until real per-university closing-merit
  numbers (not formulas — actual historical cutoffs) are loaded. The
  new Merit & Entry Test Guide (formulas, not closing merits) is a
  separate, already-live feature — don't conflate the two.
- Institute ranking uses one `<select>` per rank slot, not real
  drag-and-drop. Functionally equivalent, simpler to keep dependency-
  free. Swap in a DnD library later if wanted.
- No admin UI yet for editing institutes/faculties/merit formulas —
  all master data is edited via SQL seed files or the Supabase Table
  Editor directly.
- Merit formula data is not yet surfaced inside the actual ranked-
  institute-preference step of the form — only in the "View all
  universities" modal and the dedicated `merit.html` page.

## Frontend design pass (Manifest)

`pathways.html` now has a live-updating "Manifest" side rail
(`#fp-progress` repurposed, see `renderProgress()` / `manifestValue()`
in `js/fp-app.js`) — each line reflects real form state, not just step
position. At the review step it becomes the finale: `.fp-layout`
collapses to one column, `body.is-review-step` styling kicks in, the
submit button becomes `.btn-transmit` ("Transmit application"), and a
mono UTC timestamp stamps in on success (`state.submittedAt`).
`admin.html` got a `#fp-stats-strip` (total/submitted/draft/by-pathway
counts, computed client-side from the already-loaded `submissions`
array — no new query). No IDs or data flow changed; this was a
CSS + presentation-layer pass on top of the existing logic.

## If something seems broken

Don't trust old chat descriptions of "current state" — clone the repo
fresh and read the actual files and `git log`. Check the live Supabase
tables directly (Table Editor) rather than assuming a schema file was
actually run. Check the live Vercel deployment's commit hash against
`git log` before assuming a fix is live.
