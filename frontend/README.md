# Future Pathways — Frontend (Next.js)

Foundation-milestone app: landing page, Supabase email/password auth
(signup + login), and role-gated dashboard shells for `student` and
`admin`. No questionnaire, recommendation, or data-management UI yet.

## Structure

```
frontend/
├── middleware.ts                    — refreshes the Supabase session on every request
├── src/
│   ├── app/
│   │   ├── page.tsx                 — landing page
│   │   ├── layout.tsx / globals.css
│   │   ├── (auth)/login/page.tsx
│   │   ├── (auth)/signup/page.tsx
│   │   ├── auth/callback/route.ts   — exchanges Supabase redirect codes for a session
│   │   ├── student/dashboard/page.tsx   — student-only shell (redirects otherwise)
│   │   └── admin/dashboard/page.tsx     — admin-only shell (redirects otherwise)
│   └── lib/
│       ├── supabase/client.ts       — browser Supabase client
│       ├── supabase/server.ts       — server Component / Route Handler client
│       ├── supabase/middleware.ts   — session-refresh logic used by middleware.ts
│       └── api.ts                   — fetch wrapper that calls the FastAPI backend with the session's bearer token
```

## How auth + roles work here

Supabase Auth issues the session; `@supabase/ssr` keeps it in sync between
browser and server via cookies. New self-signups are always `role:
"student"` (set in `user_metadata` at signup time as a hint only —
dashboard guards and the backend both check `app_metadata.role`, which
only admin provisioning can set, so a student can never promote
themselves by editing their own signup payload). Each dashboard page
checks the session server-side and redirects if the role doesn't match.

## Local development

Requires Node.js 18.18+.

```bash
cd frontend
npm install
cp .env.local.example .env.local   # then fill in Supabase URL/anon key
npm run dev
```

Visit `http://localhost:3000`.

**Not yet done in this environment:** `npm install` could not actually be
run here (no network access in this sandbox), so the dependency versions
are declared but unverified against a real install/build. Run the steps
above locally to confirm `npm run dev` / `npm run build` succeed.
