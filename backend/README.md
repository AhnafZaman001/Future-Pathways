# Future Pathways — Backend (FastAPI)

Foundation-milestone API. Verifies Supabase-issued user sessions and
exposes role-gated endpoints; does not yet implement questionnaire,
recommendation, or admin data-management logic.

## Structure

```
backend/
├── app/
│   ├── main.py                 — FastAPI app, CORS, router registration
│   ├── core/
│   │   ├── config.py           — env-driven settings (pydantic-settings)
│   │   └── supabase.py         — anon-key Supabase client (session verification)
│   └── api/
│       ├── deps.py             — get_current_user / require_admin dependencies
│       └── routes/
│           ├── health.py       — GET /health (unauthenticated)
│           ├── students.py     — GET /students/me (authenticated)
│           └── admin.py        — GET /admin/ping (admin-only)
├── requirements.txt
└── .env.example
```

## How auth works here

The frontend sends the Supabase session's access token as
`Authorization: Bearer <token>` on every API call (see
`frontend/src/lib/api.ts`). `get_current_user` verifies that token against
Supabase Auth itself (`auth.get_user`) rather than trusting the frontend —
so a request can't claim a role or identity the real session doesn't have.
Role (`student` | `admin`) is read from the user's `app_metadata`, which
only privileged provisioning (Supabase Admin API) can set — students can't
elevate themselves via self-signup.

## Local development

Requires Python 3.11+.

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env        # then fill in SUPABASE_URL / SUPABASE_ANON_KEY
uvicorn app.main:app --reload --port 8000
```

`GET http://localhost:8000/health` should return `{"status": "ok"}`.

**Not yet done in this environment:** `pip install` could not actually be
run here (no network access in this sandbox), so the dependency versions
in `requirements.txt` are pinned but unverified against a real install.
Files were checked with `python -m py_compile` (syntax only). Run the
steps above locally to confirm they install and boot cleanly.
