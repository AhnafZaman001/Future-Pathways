# PROGRESS.md — ground truth as of this commit

This file exists so a new Claude session (or you, months later) doesn't
have to reconstruct the state of this project from chat history. If
anything here conflicts with what a chat says, **trust this file and
the actual repo/database — re-verify by cloning fresh and checking
Supabase directly.**

## What this project is

"Rah" — a Pakistani university/college counselling tool. Two things
live in one repo:

1. **The dashboard** (`index.html`) — the landing page after login.
   Used to be a "quick calculator" (matric + FSc Part 1 marks in,
   provisional merit score + suggested universities out) — that was
   the original prototype, but it duplicated the marks intake already
   in Future Pathways and the field/university browsing already in
   University Explorer, so it was removed. `index.html` is now a real
   dashboard: it reads the student's existing `students` row and
   latest `future_pathways` row from Supabase (no re-asking) and shows
   their actual application status (not started / draft / submitted)
   plus quick links into the three tools below. Logic lives in
   `js/dashboard.js`; the old calculator-only files (`js/app.js`,
   `js/calculations.js`, `js/suggestions.js`, `js/supabase-client.js`,
   `js/ui.js`) were deleted. `js/data.js` (institute loader) is kept —
   the dashboard's "View all universities" modal still uses it.
2. **Future Pathways** (`pathways.html` + `admin.html`) — the real
   product: digitizes an actual paper counselling form used by a
   school. Multi-step form, ranked institute/faculty preferences,
   draft autosave, one-submission-per-student, counsellor/admin
   evaluation panel.
3. **University Explorer** (`rankings.html`) — browse field/
   specialization rankings independent of any student's own marks.

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

- `Counsellor.MERIT_FEATURE_ENABLED = false` in `js/data.js` is now
  **dead** — it only gated the old quick calculator's Strong/
  Competitive/Unlikely scoring, and that calculator (`js/suggestions.js`
  etc.) was deleted when `index.html` became a dashboard. Safe to
  remove along with the rest of `Counsellor.FIELDS` / `AREAS` /
  `MERIT_WEIGHTS` next time someone's in `data.js` — left in place for
  now since `Counsellor.loadInstitutes()` / `Counsellor.INSTITUTES` in
  the same file are still used by the "View all universities" modal.
  The Merit & Entry Test Guide (`merit.html`, formulas not closing
  merits) is unrelated and already live — don't conflate the two.
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

## Home dashboard: "Recently saved student forms" widget

`index.html` now has a small `#fp-dash-section` (new
`js/fp-saved-forms.js`) below the tool cards, showing the 8
most-recently-saved `future_pathways` rows with a click-to-open
read-only preview modal (profile, careers, ranked institute/faculty
preferences). It's `hidden` by default and only unhidden when the
signed-in `app_users.role` is `counsellor` or `admin` — same gate
`admin.html`/`js/fp-admin.js` already uses, checked client-side only
(RLS on the underlying tables is what actually enforces this).

This does **not** replace `admin.html` — that page still has the full
filterable table, submission stats strip, and office-evaluation
editing. The new widget is a lightweight glance + link out to
`admin.html` for anyone who wants the full view, since `admin.html`
isn't linked from the main nav.

## If something seems broken

Don't trust old chat descriptions of "current state" — clone the repo
fresh and read the actual files and `git log`. Check the live Supabase
tables directly (Table Editor) rather than assuming a schema file was
actually run. Check the live Vercel deployment's commit hash against
`git log` before assuming a fix is live.

## Page-load performance fix (auth-blocking-content pattern)

Every page had the same bug: `FP.requireAuth()` does two sequential
round-trips internally (session, then a separate `app_users` role
lookup), and every page's own content queries waited behind the
**full** result of that before even firing. Four sequential round-
trips stacked up on `admin.html` alone (auth → institutes/faculties/
careers → first-priorities → submissions).

Fixed by firing content queries immediately, in parallel with the
auth check, since RLS enforces access server-side regardless of when
the client-side profile fetch resolves — there's no correctness
reason for the queries to wait on each other:

- **`pathways.html` / `merit.html`** — neither page ever reads role at
  all. Dropped `FP.requireAuth()` entirely; use
  `FP.client.auth.getSession()` directly (resolves from local storage
  in the common case, no network round-trip) for the redirect-if-not-
  logged-in check + `studentId`. Content queries that don't need
  `studentId` either (`loadMasterData()`, `FP.loadMeritFormulas()`,
  `FP.loadClosingMerit()`) fire before the session is even known.
- **`index.html` / `admin.html`** — these do need role (branches UI
  on counsellor/admin vs student), so `FP.getSessionAndProfile()`
  stays, but content queries now fire in parallel with it instead of
  waiting behind it.
- **`admin.html`**'s own internal chain (`loadLookups().then(loadFirstPriorities).then(loadSubmissions)`)
  was *also* three sequential round-trips with no real dependency
  forcing that order — now all fire together, with only the
  *processing* of results sequenced (institute names need to be
  loaded before first-priority display names can be resolved, but the
  fetches themselves don't need to wait).

If a future page needs role-gated behavior and reaches for
`FP.requireAuth()` again out of habit, check whether the content
below it actually needs role before letting it block everything else.

## Recent fixes (branding, nav, casing, region search)

- Brand renamed `Rah` → `KIPS` across all 6 HTML files (verified zero
  leftover references, including JS/CSS).
- `index.html` had the same 3 links (Future Pathways form / University
  Explorer / Merit guide) as both top-nav pills *and* body tool cards
  — removed the duplicate pills, kept the better-designed cards
  (icon + description + CTA).
- Text casing was inconsistent across `admin.html`'s table and the
  dashboard's "Recently saved forms" widget: student names in ALL CAPS
  (real source data from the school's own export), pathway/status in
  lowercase, no shared convention. Added a `titleCase()` helper
  (display-only, doesn't mutate stored data) for names, and
  `text-transform: capitalize` CSS (`.fp-cap`, and added directly to
  `.fp-badge`) for pathway/status — same fix duplicated in both
  `js/fp-admin.js` and `js/fp-saved-forms.js` since they're separate
  IIFEs with no shared module system.
- University Explorer (`rankings.html`) City filter: **first version
  of this was wrong** — built as a separate standalone search section
  below the Field/Specialization card instead of a third filter
  integrated into the same one, which wasn't what was asked for and
  was correctly rejected. Corrected version: `.fp-grid-3` (new,
  mirrors `.fp-grid-2`), City is a third `<select>` in the *same*
  `.rk-selector` card, populated from `institutes.location` +
  `institutes.campuses` (real data, fetched immediately on script
  load — this page has no auth gate). It filters the *same* ranked
  results and "Also offered at" list that Field/Specialization
  produce (via a canonical-name → cities map, reusing the existing
  `INSTITUTE_ALIAS` display-name mapping), not a separate result set.
  An institute not present in `institutes` (i.e. not in the seeded
  table, only in the curated `rankings-data.js` content) has no known
  city and is correctly excluded when a city filter is active, rather
  than guessed.

## Light theme + theme toggle

Not a color inversion — a second set of tokens sharing the same bones
(type scale, spacing, radii, the same `--violet` accent hue for
button fills) as the dark theme, recalibrated where the underlying
math actually differs between a near-black and a near-white canvas:

- **Elevation reverses.** Dark theme cards read "raised" by being
  *lighter* than canvas. That trick doesn't work near white (reads as
  dirty gray, not elevated), so light-theme cards are pure white with
  a `--shadow-card` token (`.fp-card` now has
  `box-shadow: var(--shadow-card, none)` — `none` in dark mode where
  the token isn't defined, an actual soft shadow in light mode).
- **`--violet-text` exists because contrast math isn't symmetric.**
  The brand violet (`#6E76F0`) works fine as white-on-violet button
  fill, and fine as violet-on-black body text — but fails WCAG AA
  (3.8:1, need 4.5:1) as violet text directly on a white canvas
  (links, `.eyebrow` labels). Rather than retune `--violet` itself
  and risk the button fill or dark-mode text, only that specific
  usage gets a deepened same-hue variant (`#4B44D6`, ~6.8:1 on
  white) via a separate token. `a{color}` and `.eyebrow{color}` in
  `styles/base.css` use `--violet-text`, not `--violet` directly —
  keep that distinction if adding new violet-on-canvas text anywhere.
- Green/amber/red also got darkened light-mode variants for the same
  contrast reason (status badges, error/success text).
- The ambient aurora background (`body::before/::after` +
  `html::before` noise layer in `base.css`) now reads its color stops
  from `--aurora-a-stops` / `--aurora-b-stops` / `--aurora-noise-opacity`
  tokens instead of hardcoded rgba values, so light mode can retune
  intensity (lower opacity — the same values would be too strong on
  white) without duplicating the whole layer/animation setup.

**Switching mechanism:** `data-theme="light"` attribute on
`<html>`, persisted to `localStorage` (`kips-theme`). Two parts:
1. A tiny synchronous inline script at the very top of every page's
   `<head>` (before any CSS loads) applies the saved choice
   immediately, avoiding a flash of the wrong theme on load.
2. `js/theme-toggle.js` (new, shared, loaded on every page) handles
   the actual click-to-switch and updates the toggle button's label.

**The toggle control is deliberately not a sun/moon icon-swap or a
sliding pill switch** — the two most overused patterns for this
exact UI element. It's a single circle split into a filled half and
a hollow half (`.theme-toggle-glyph`, a `conic-gradient` + border,
no SVG/icon font needed) that rotates 180° on click — one object
turning over, not two icons cutting between each other. Lives in
`styles/components.css` next to `.nav-link` (same family: pill
shape, same padding/sizing) since it's a nav-adjacent control, not a
one-off page-specific button.

**Every page has one**, positioned consistently: right before "Log
out" on the four authenticated pages (`index.html`, `pathways.html`,
`admin.html`, `merit.html`), at the end of the topbar on
`rankings.html` (no logout button there), and next to the brand mark
in `login.html`'s header (no topbar at all on that page — see
`.header-top`, the same row-layout wrapper `index.html` etc already
use around `.brand`, applied there for the first time).

**Verified visually**, not just written and trusted: rendered both
themes via headless Chromium (actual click-through, not just setting
the attribute), and a separate component-swatch render (buttons,
badges, links, error/success text, the toggle itself) side-by-side in
both themes to check contrast on the recalibrated status colors
specifically. Re-check the same way if the palette changes again.

## Counsellor-managed students (built)

**The real workflow:** a counsellor sits at a desk, brings students
up in batches, and enters each student's info + preferences directly
on their behalf, in one sitting. Confirmed directly with the person
doing this job: the student never logs in themselves at all — the
counsellor manages everything.

**Root cause of the original bug report** ("it treats me like I'm a
student and won't let me edit, but the admin panel shows everyone"):
RLS write policies were read-permissive but write-blind for staff.
`using (id = auth.uid() or is staff)` already let a counsellor see
every student — that's why `admin.html` could already list everyone.
But `with check (id = auth.uid())` on those same policies meant a
counsellor could never actually *write* on behalf of anyone but
themselves. Separately, `pathways.html` had zero concept of "editing
someone else's form" — hard-wired to `auth.uid()` as the one student
it could ever represent.

**What was built**, `supabase/counsellor_managed_students.sql` +
`js/fp-app.js` + `admin.html`/`js/fp-admin.js`:

1. **Fixed the RLS write policies** on `students`, `future_pathways`
   (insert/update), and all three preference tables — added a staff
   bypass to the `with check` clause of each (previously only the
   `using` clause had one), and let staff write regardless of the
   submission's current status (needed to edit an already-submitted
   form).

2. **`counsellor_create_student()`** — a `security definer` RPC,
   staff-only (checked internally via `current_role()`, not just by
   grant). Creates a new, non-login-capable `auth.users` row (same
   shape as `load_test_seed_100_students.sql` — no `auth.identities`
   row, no real password hash, since this student is confirmed to
   never need to log in) and returns its id. Does **not** pre-create
   the `students`/`future_pathways` rows — those still come from the
   existing lazy-create logic already in `js/fp-app.js`
   (`ensureFuturePathwayRow()` / `saveProfile()`), unchanged, the same
   way they already work for a real self-service student. This RPC
   only creates the backing account those inserts require.

3. **`counsellor_reset_submission(p_future_pathway_id)`** — another
   `security definer` RPC. Implements "delete a student's form" per
   the confirmed meaning: **keep the account** (the `students` row —
   name, roll number, marks — untouched) and **clear the answers**
   (deletes all three preference tables' rows for that submission,
   clears `additional_information`, resets `status` to `'draft'` and
   `submitted_at` to `null`). Not a hard delete of anything
   identity-related.

4. **`pathways.html?student=<id>`** — `js/fp-app.js` now branches on
   this query param. Absent (the normal case): unchanged, same fast
   session-only boot path as before, no role fetch. Present: does the
   full `FP.getSessionAndProfile()` role check (only staff can
   proceed; anyone else sees a plain "this link is for
   counsellors/admins" message, backed by RLS regardless), then sets
   `state.studentId` to the URL param instead of the caller's own id
   and `state.actingAsStaff = true`. That flag: unlocks the
   Save/Transmit button and the step-advance guard even when
   `status === 'submitted'` (both previously hard-blocked past
   submission for everyone), and swaps the status banner for a
   distinct "Editing on behalf of &lt;name&gt;" one instead of the
   normal student-facing draft/submitted banners.

5. **`pathways.html`** — "+ Add new student" button lives in the
   form page's own topbar (calls `counsellor_create_student()`, then
   navigates to `pathways.html?student=<new id>`). Deliberately
   **not** on `admin.html` — an earlier version put it there, which
   meant clicking it just redirected straight back to
   `pathways.html` anyway (admin → create → land on the form page)
   for no reason; `admin.html` is view-only for the submissions list
   now. `admin.html`'s detail view still has "Edit this form" (same
   `?student=` redirect, for an existing student) and "Reset to
   draft" (calls the reset RPC, confirms first, re-renders in
   place) — those stayed, since acting on a record you're already
   looking at isn't the same "extra hop" problem as the add button
   was.

**Not built / intentionally out of scope**, since it wasn't what was
asked for: a real hard-delete of a student's account/identity (the
confirmed meaning of "delete" was reset-to-draft, not erase); any
UI for a student to log in and see their own status (confirmed they
never will); a separate "quick add" form for student info at creation
time (the RPC creates a bare account and redirects straight into the
existing multi-step form instead, which already collects that exact
information — no need to duplicate it).

## Preference-group accordion (admin detail view)

The dean wanted, per-student, a way to see each of the 4 preference
groups' 5 ranked picks (institute pathway: 4 groups; medical: 2) —
initially described as "four dropdowns" in a table, which doesn't
work (a table's job is scanning many students at once; 20 data
points per row would break that). Once clarified this was about the
*detail* page for one student, not the list, the actual ask was much
simpler: this data already existed there (`groupedRows()` in
`js/fp-admin.js`), just as always-visible flat text, not collapsible.

Replaced with `groupedAccordion()`: four independently-collapsible
sections (not tabs — more than one can be open at once, e.g.
comparing group 1 against group 3 without losing either). Used for
both Institute preferences and Faculty preferences in the detail
view (`groupedAccordion(rows, nameLookup, idPrefix)` — the
`idPrefix` param, `"inst"`/`"fac"`, keeps their panel element ids
from colliding since both call the same function on the same page).

**A real bug caught before shipping**, not just written and trusted:
the first version manually prepended `"1. "` etc. to each list item
*and* rendered them inside a native `<ol>`, which auto-numbers on its
own — result was literal "1. 1. NUST" double-numbering, confirmed via
an actual headless-Chromium render, not just reading the code. Fixed
by using `<li value="N">` instead of manual text prefixes — lets the
browser's native numbering do the work while still showing the
*real* rank number (not a re-numbered sequential count) when a
group has gaps, e.g. a partially-filled draft missing rank 3 still
correctly shows "1, 2, 4, 5", not "1, 2, 3, 4" — verified with a
render that deliberately included a gap.

## Calculate Your University Merit (`merit-calculator.html`)

Distinct from both `merit.html` (informational — shows each
institute's formula as text) and `program_closing_merits`/
`closing_merit_records` (last year's actual cutoffs) — this is a
real interactive calculator: enter your actual marks, get the exact
weighted aggregate for a specific university/program route.

```
merit-calculator.html         — the page
js/merit-calculator-data.js   — the formulas (not in Supabase —
                                 pure client-side data + arithmetic,
                                 no DB round-trip needed to compute)
js/merit-calculator.js        — controller: renders fields per
                                 selected university, validates,
                                 computes, shows the breakdown
```

Covers NUST (NET-basis), FAST-NUCES (Computing/Business AND
Engineering — two different formulas at the same university),
GIKI, PIEAS, and UET — sourced from Parhlai's and UniCalc's own
merit calculators, both explicitly named when this was requested.

**A real formula error was caught and fixed before shipping, not
guessed at:** the first fetch of Parhlai's GIKI page showed "10%
Matric + 85% Test" — which only sums to 95%, a sign of a mis-scrape,
not a real formula (a calculator that can't reach 100% is an obvious
bug). Cross-checked against ilmkidunya.com and CampusAxis
independently — both confirm 15% + 85%, with FSc/Intermediate
marks explicitly **not** weighted at all (eligibility-only, 60%
minimum). That's why GIKI's calculator only has two fields, not
three — verify this kind of thing before shipping a number, don't
assume the first source is right.

**The arithmetic was verified by actually running it**, not trusting
the code: rendered the real compute logic in headless Chromium,
manually calculated the expected result by hand for two different
universities, and confirmed the on-screen output matched exactly
(NUST: 90% SSC + 85% HSSC + 160/200 NET → 81.75%; GIKI: 92% Matric +
170/200 test → 86.05%). Also verified the validation path (empty/
out-of-range fields correctly block calculation and highlight in
red) and that `(num / maxMarks) * 100` correctly converts a "marks"-
type field (NET, GIKI's test — both scored out of 200) before
applying its weight, versus a "percent"-type field (SSC, HSSC, FAST's
test, PIEAS's percentile) which is used as entered.

**Not built / intentionally out of scope:** NUST's ACT/SAT-basis
route (same weights, but ACT/SAT use a different scale — 36 / 1600 —
that needs its own conversion, not just a different max, and wasn't
part of what was asked); O-Level/A-Level grade-to-percentage
equivalence tables (each university has its own table for this;
genuinely substantial additional research per university, out of
scope for what was requested — this version expects a percentage
input, which covers Matric/FSc board students directly and requires
O/A-Level students to convert their own grades first); universities
beyond the five named when this was requested.

**Revised after initial feedback:**
1. Matric/SSC and FSc/HSSC are now entered as obtained + total marks
   (`type: "marks_variable"` in `merit-calculator-data.js`), not a
   direct percentage — the tool computes the percentage itself.
   Only fields that are already a percentage with no natural "out of"
   total (a test percentage, PIEAS's percentile) still take a direct
   percent input.
2. The result no longer shows a per-component breakdown — just the
   final aggregate, plus a link to University Explorer to compare
   against last year's closing merit.
3. **The "SOURCE: Parhlai / UniCalc" line was removed from the
   calculator UI entirely.** `sourceUrl`/`sourceLabel` still exist in
   `merit-calculator-data.js` — kept for internal maintainability, so
   a future update knows where a formula came from — but nothing
   reads them for display anymore.

## Important: don't cite sources where they're not load-bearing

Direct instruction, worth keeping in mind for anything built after
this: **citing an external site on a page where the citation isn't
actually doing work for the reader makes the product look cheap** —
like a thin wrapper around someone else's tool, not something built
with its own credibility. This is why the merit calculator shows no
"powered by" or "source:" line, even though its formulas originated
from Parhlai/UniCalc.

The distinction that matters: cite where the citation is *load-
bearing* — the Merit & Entry Test Guide and University Explorer
pages, where a `confidence` rating and a source link are the whole
point (the reader needs to judge how much to trust a number). Don't
cite on a tool where the person is entering *their own* data and
getting *their own* result — the source of the formula isn't
what they came for, and naming it there just reads as borrowing
someone else's credibility instead of standing on the product's own.
Applies to future pages too, not just this one — check which kind of
page something is before deciding whether a source line belongs on
it.

## Interaction design pass

Applied the `interaction-design` skill's principles (purposeful
motion, transform/opacity-only for perf, consistent timing scale,
`prefers-reduced-motion` respected) — translated into vanilla CSS/JS
since this app has no React/Framer Motion and the skill's own
examples assume both.

1. **Timing/easing tokens** in `base.css` —
   `--dur-micro/small/medium` (120/220/320ms) and
   `--ease-out/in-out/spring`. Every transition added below pulls
   from these instead of ad-hoc per-rule values; use them for
   anything added later too, don't reintroduce hardcoded durations.
2. **Buttons** — real press feedback (`scale(.98)` on `:active`) and
   hover lift. Applied to both `.btn-primary` definitions — yes,
   there are two (`components.css` and `pathways.css`, pre-existing
   duplication, not consolidated here, out of scope) — kept
   identical so the feel doesn't differ between pages.
3. **Dashboard tool cards** — hover now lifts (`translateY(-3px)` +
   shadow) instead of just swapping colors. **Caught a real bug
   while testing this**: hovering a card underlined its text,
   inherited from a global `a:hover{text-decoration:underline}` rule
   the card never overrode for its own hover state. Fixed
   (`.dash-tool-card:hover{ text-decoration:none; }`) and confirmed
   gone via render — worth knowing this pattern can bite any other
   `<a>`-as-card component added later.
4. **Accordion** (admin detail view preference groups) — was an
   instant `hidden`-attribute toggle, zero transition possible
   (`display` can't be animated). Replaced with the CSS Grid
   `grid-template-rows: 0fr → 1fr` technique — animates truly
   auto-height content without JS measuring it first. Required a
   markup change (`fp-accordion-panel` is now wrapped in
   `fp-accordion-panel-wrapper`, which is the grid; toggling adds/
   removes an `.is-open` class instead of the `hidden` attribute) in
   both `js/fp-admin.js` (markup generation) and the click handler.
5. **Modal entrance/exit** (the "View all universities" modal, two
   separate implementations in `js/dashboard.js` and `js/fp-app.js`)
   — was an instant `hidden` toggle. Now fades + scales in/out.
   Needed real JS choreography, not just CSS: on open, clear
   `hidden` → force a reflow (`void overlay.offsetWidth`) → add
   `.is-open` (skipping the reflow means the browser coalesces the
   attribute change and the class addition into one paint and the
   transition never plays). On close, remove `.is-open` first, then
   `setTimeout` the `hidden = true` re-application to match
   `--dur-medium` — otherwise `hidden` would cut the exit animation
   off instantly. The `setTimeout` callback checks
   `!classList.contains("is-open")` before hiding, guarding against
   a rapid close-then-reopen leaving the modal incorrectly hidden.
6. **Merit calculator result reveal** — new shared `.reveal-in`
   keyframe (`base.css`: fade + `translateY(8px)→0`), applied to the
   result card when it appears after clicking Calculate. Reusable
   for any future "this just happened" moment (a save confirmation,
   etc), not calculator-specific.

**Verified every one of these by actually rendering it in headless
Chromium**, not by reading the CSS and assuming it's right — same
discipline as the rest of this project. Specifically: card hover
screenshotted before/after the underline fix; accordion screenshotted
with both groups open independently; modal screenshotted at rest,
mid-open, fully open, mid-close, and fully closed (confirming
`overlay.hidden` actually re-applies after the close animation, not
just that the CSS looks plausible); calculator result screenshotted
early-in-animation and settled, with the underlying math re-verified
correct (GIKI: 990/1100 Matric + 170/200 test → 85.75%).

