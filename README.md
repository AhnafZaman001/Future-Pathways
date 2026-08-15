# Future Pathways

A student-facing tool that takes matric marks, FSc Part 1 marks, field of
study, and preferred city, and suggests university/program preferences —
with eligibility against historical closing merits once that data is added.

**Status: quick vanilla HTML/CSS/JS prototype.** No build step, no backend,
no database — everything runs client-side in `index.html`. This replaces an
earlier Next.js + FastAPI + Supabase architecture that was scaffolded but
not built out; that plan is no longer what this repo tracks.

## Run it

Clone the repo and open `index.html` directly in a browser. No server,
no `npm install`, nothing to build.

## Structure

```
Future-Pathways/
├── index.html              — page shell, form markup
├── styles/
│   ├── base.css             — tokens: colors, type, resets
│   ├── layout.css           — structure/grid only
│   └── components.css      — inputs, buttons, cards, badges, gauge
├── js/
│   ├── data.js              — fields, cities, merit weights, UNIVERSITIES dataset
│   ├── calculations.js     — pure functions: percentages, provisional merit score
│   ├── suggestions.js      — matches/ranks universities against a student profile
│   ├── supabase-client.js — only file that talks to Supabase (insert-only)
│   ├── ui.js                — DOM rendering
│   └── app.js              — form event wiring, glues the modules together
└── supabase/
    └── schema.sql          — run once in the Supabase SQL Editor
```

## Database (Supabase)

Every submission is written to a `student_submissions` table in Supabase
instead of staying only in the browser.

**One-time setup:** open your Supabase project → SQL Editor → paste and
run `supabase/schema.sql`. It creates the table, adds a Row Level
Security policy so the public key can only **insert** rows, and grants
the `anon` role the actual Postgres `insert` privilege — RLS policies
alone don't expose a table to the Data API; the explicit `grant` is
required too, and it's easy to miss. View collected submissions from the
Supabase dashboard's Table Editor, which has full access regardless of
RLS.

`js/supabase-client.js` holds the project URL and the **publishable
(anon) key** — this key is meant to be public/client-side, unlike the
service role key or database password, which should never go in this
repo or in browser code.

## How it works

1. Student enters name, matric obtained/total, FSc Part 1 obtained/total,
   field of study, preferred city.
2. `calculations.js` computes a **provisional merit score** per field
   (weights in `Counsellor.MERIT_WEIGHTS`, `js/data.js`) — matric + FSc
   Part 1 only, since Part 2 and the entry test aren't available yet. It
   reports a "score so far" and a "best-case ceiling" (if the pending
   entry-test weight were scored at 100%).
3. `suggestions.js` filters `Counsellor.UNIVERSITIES` by field, ranks
   preferred-city matches first, and classifies each program as Strong
   Chance / Competitive / Unlikely / Merit data needed by comparing the
   score against that program's `closingMerit`.
4. `ui.js` renders the results as cards with a radial score gauge.

## Adding real data

`js/data.js` is the only file meant to change often. Every
`closingMerit` is currently `null` on purpose, so cards show "Merit data
needed" instead of a guess. Fill in real historical closing merits per
program and the cards automatically switch to a real classification — no
other file needs touching.

## Not in this prototype

- No historical merit data (placeholders only — see above)

## Future Pathways form (`pathways.html`, `auth.html`, `admin.html`)

A separate, full multi-step preference-submission flow sits alongside the
quick merit calculator above. It has its own auth, own Supabase tables,
and its own JS modules — it does not touch `student_submissions` or the
calculator's files.

```
auth.html          — student sign up / log in (Supabase Auth)
pathways.html       — the multi-step form itself
admin.html          — counsellor/admin: list submissions, filter, enter
                       the 12-recommendation office evaluation
js/fp-client.js     — shared Supabase client + auth helpers
js/fp-app.js        — student form: steps, validation, draft save, submit
js/fp-admin.js       — admin list + detail + evaluation form
styles/pathways.css — styles for all three pages (reuses base.css tokens)
supabase/future_pathways_schema.sql — tables, roles, RLS (run once)
supabase/future_pathways_seed.sql   — institutes/faculties/programs/careers (run once, after schema)
```

**One-time setup**, in the Supabase SQL Editor, in order:
1. `supabase/schema.sql` (if not already run)
2. `supabase/future_pathways_schema.sql`
3. `supabase/future_pathways_seed.sql`

New signups default to the `student` role (via a trigger on
`auth.users`). To make someone a counsellor/admin, update their row in
`app_users` from the Supabase dashboard: `update public.app_users set
role = 'counsellor' where id = '<their auth uid>';`

**Flow:** student information → pathway (engineering/medical) →
programs & career interests → ranked institute preferences (4 groups of
5 for engineering, 2 of 5 for medical) → ranked faculty preferences
(same grouping) → additional information → review → submit. Each step
autosaves to a `future_pathways` draft row; a partial unique index
blocks a second *submitted* row per student. Once submitted, RLS blocks
further edits from the student side.

**Ranking UI note:** preference ranking uses one dropdown per rank slot
(with duplicate-selection warnings) rather than drag-and-drop, to keep
this a no-build-step, vanilla-JS project. Swap in a drag-and-drop
library later if wanted — the data model (`preference_group`, `rank`)
doesn't need to change.

**Not done yet:** admin management UI for adding/editing institutes,
faculties, and program/career options (currently edited directly via
`supabase/future_pathways_seed.sql` or the Supabase dashboard).
