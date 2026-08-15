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

- No backend, no database, no auth
- No historical merit data (placeholders only — see above)
- No admin tooling for managing the university dataset (currently a
  hand-edited array in `data.js`)
