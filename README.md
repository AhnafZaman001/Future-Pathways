# Future Pathways

A student-facing SaaS that digitalizes the KIPS Future Pathways process:
adaptive questionnaire → academic profile → career/program/university
recommendations, with eligibility, historical closing merit, fees, admission
deadlines, and Safe / Target / Reach classification.

Users: **student**, **admin**. There is no counselor functionality.

## Project status

| Area | Status |
|---|---|
| Database architecture | Approved (`docs/architecture/future-pathways-db-architecture-v3-final.md`) |
| Database migration | Written, locally tested (24/24 checks), **not yet applied to remote Supabase** |
| Repository / Supabase CLI setup | Done |
| Frontend | **Foundation milestone: landing page, Supabase auth (signup/login), student & admin dashboard shells** |
| Backend (Python) | **Foundation milestone: FastAPI app, session verification, role-gated shell endpoints** |
| Questionnaire UI | Not started |
| Recommendation engine | Not started |
| Seed data | Not started |

This repo is being built incrementally, milestone by milestone. The
"application foundation" milestone (frontend + backend scaffolding, auth
wiring, dashboard shells) is in place; feature work (questionnaire,
recommendations, admin data tools, seed data) has not started. Neither
`npm install` nor `pip install` has been run against these new
`frontend/`/`backend/` directories yet in this environment — see each
directory's README for the exact local-dev commands to verify them.

## Repository structure

```
Future-Pathways/
├── README.md                          — this file
├── .gitignore
├── docs/
│   └── architecture/
│       └── future-pathways-db-architecture-v3-final.md   — approved architecture (source of truth)
├── supabase/
│   ├── config.toml                    — Supabase CLI project config (local dev)
│   ├── migrations/                    — approved, ordered SQL migrations
│   │   ├── README.md
│   │   ├── 20260812120001_schema.sql
│   │   ├── 20260812120002_functions_triggers.sql
│   │   └── 20260812120003_rls_policies.sql
│   ├── docs/                          — migration review deliverables
│   │   ├── D_constraints_explanation.md
│   │   ├── E_verification_checklist.md
│   │   ├── F_implementation_deviations.md
│   │   └── ORIGINAL_MIGRATION_PACKAGE_README.md
│   └── tests/
│       └── local-dev/                 — local-only test harness, NOT applied to Supabase
│           ├── README.md
│           ├── 000_auth_stub.sql
│           ├── 999_test_harness_grants.sql
│           └── run_tests.sql
├── frontend/                          — Next.js + TypeScript + Tailwind (foundation milestone)
│   └── README.md                      — structure + local dev instructions
└── backend/                           — Python + FastAPI (foundation milestone)
    └── README.md                      — structure + local dev instructions
```

## Development setup (Supabase CLI, migration-based)

This project uses the Supabase CLI's standard migration workflow: schema
changes live as ordered `.sql` files in `supabase/migrations/`, applied in
filename order.

### Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- Docker (for local Supabase stack)
- Access to the `Future Pathways` Supabase project (for staging/production
  steps only — not needed for local dev)

### 1. Local development stack

From the repo root:

```bash
supabase start
```

This spins up a full local Supabase stack (Postgres, Auth, Studio, API) in
Docker, with a real `auth` schema — so the `supabase/tests/local-dev/`
stub files are **not** needed for this path.

Apply the migrations to it:

```bash
supabase db reset
```

(`db reset` recreates the local DB from scratch and applies everything in
`supabase/migrations/` in order — the standard way to test migrations
locally.)

### 2. Linking to the remote project (not yet done)

Once ready to point at the real `Future Pathways` Supabase project:

```bash
supabase link --project-ref <project-ref>
```

This requires the project ref from the Supabase dashboard and CLI login
(`supabase login`). **Not run as part of this task** — no service-role keys,
passwords, or project refs are stored in this repo or requested in chat.

### 3. Applying migrations to the remote project (not yet done)

Once linked, and only after explicit review/approval:

```bash
supabase db push
```

This applies any migrations in `supabase/migrations/` not yet recorded as
applied on the remote project. **This has intentionally not been run.** The
migration is written and locally tested but has not been executed against
the real Supabase project.

### 4. Creating new migrations going forward

```bash
supabase migration new <descriptive_name>
```

This creates a correctly-timestamped empty file in `supabase/migrations/`
ready to edit — the convention the three existing migration files already
follow.

## Migration contents

See `supabase/migrations/README.md` for what each of the three files
contains, and `supabase/docs/` for the full review material:

- **D** — explanation of important constraints, by architectural decision
- **E** — verification checklist (what's been tested locally vs. what still
  needs verifying against real Supabase)
- **F** — every implementation deviation from the approved architecture,
  individually flagged (e.g. `users` = `auth.users`, role via JWT
  `app_metadata`, no counselor role)

The architecture itself (`docs/architecture/`) is the source of truth and
has not been modified by this repository setup.

## Running the application foundation locally

Two independent local-dev servers, alongside the Supabase stack above:

```bash
# Backend (from repo root)
cd backend && python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in SUPABASE_URL / SUPABASE_ANON_KEY
uvicorn app.main:app --reload --port 8000

# Frontend (separate terminal, from repo root)
cd frontend && npm install
cp .env.local.example .env.local   # fill in the same Supabase values + API base URL
npm run dev
```

Then visit `http://localhost:3000`. See `frontend/README.md` and
`backend/README.md` for what each piece does and how auth is wired
between them.

## What this repository does not yet have

- Questionnaire UI or recommendation logic
- Admin data-management UI (beyond the dashboard shell)
- Seed data (universities, programs, merit history, fees, questionnaire
  content)
- Migrations applied to the remote Supabase project
- Production deployment configuration
- Verified `npm install` / `pip install` runs (no network access in the
  environment that generated `frontend/` and `backend/` — see their
  READMEs)
