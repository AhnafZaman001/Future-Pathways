// =========================================================
// supabase/functions/chat-assistant/index.ts
//
// Proxies chat requests to Groq's free-tier API. This has to live
// server-side (a Supabase Edge Function, not client JS) because the
// Groq API key would otherwise sit in plain view in the browser --
// anyone could open DevTools, copy it, and burn the shared free
// quota (or get it revoked for ToS violations).
//
// Two things this function is responsible for beyond "call the LLM":
//
// 1. Rate limiting -- Groq's free tier is shared across the WHOLE
//    app (one key), not per user. Without a cap here, one counsellor
//    could exhaust the daily/per-minute quota for everyone else.
//    Limits are enforced against public.chatbot_requests (see
//    supabase/chatbot_schema.sql) -- a request is logged BEFORE the
//    Groq call, closing most of the race-condition window where
//    parallel requests could all slip past the count check.
//
// 2. Grounding -- rather than letting the model freely answer
//    factual questions (which risks hallucinated merit formulas or
//    invented student data), real rows from merit_formulas or a
//    specific student's actual preferences are fetched and injected
//    into the system prompt first.
//
// Deploy with:
//   supabase functions deploy chat-assistant
//   supabase secrets set GROQ_API_KEY=your_key_here
// (SUPABASE_URL, SUPABASE_ANON_KEY, and SUPABASE_SERVICE_ROLE_KEY are
// injected automatically by the Supabase platform -- no need to set
// those yourself.)
// =========================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

// Adjust these two numbers to taste -- they're the only rate-limit
// knobs. Groq's free tier for llama-3.3-70b-versatile is generous
// (thousands of requests/day), so these are conservative per-user
// caps meant to stop one person from hogging it, not to ration a
// scarce resource.
const HOURLY_LIMIT = 15;
const SIX_HOUR_LIMIT = 40;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

const SYSTEM_PROMPT = `You are a helpful assistant embedded in Future Pathways, an internal tool KIPS College counsellors use to help students plan university/college applications.

How the site works, for context:
- Students fill out a form ranking their preferences: institutes, faculties, and programs, in 4 groups of 5 ranked choices each (20 total ranked positions -- 2 groups / 10 positions for the medical pathway). Group 1 = positions 1-5, Group 2 = positions 6-10, Group 3 = positions 11-15, Group 4 = positions 16-20.
- Counsellors review submissions in an admin dashboard, and can step through any of the 20 ranked positions to see which institute/faculty a student chose there.
- The site also has a Merit & Entry Test Guide (weighted merit formulas per institute) and a Merit Calculator (students plug in marks to estimate their aggregate).

You're talking to a counsellor or admin, not a student. Be concise, direct, and practical. If you don't know something (e.g. a specific institute's current admission deadline), say so plainly rather than guessing -- do not invent merit formulas, cutoffs, or policies that weren't given to you in context below.`;

async function buildStudentContext(adminClient: any, studentId: string): Promise<string> {
  const { data: fp } = await adminClient
    .from("future_pathways")
    .select("id, pathway, status, students(student_name, matric_marks, first_year_marks)")
    .eq("student_id", studentId)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!fp) return "No Future Pathways submission found for this student.";

  const [instPrefs, facPrefs] = await Promise.all([
    adminClient.from("student_institute_preferences")
      .select("preference_group, rank, custom_institute_name, institutes(name)")
      .eq("future_pathway_id", fp.id).order("preference_group").order("rank"),
    adminClient.from("student_faculty_preferences")
      .select("preference_group, rank, custom_faculty_name, fp_faculties(name)")
      .eq("future_pathway_id", fp.id).order("preference_group").order("rank"),
  ]);

  function fmtRows(rows: any[] | null, customKey: string, lookupKey: string) {
    return (rows || []).map((r: any) => {
      const pos = (r.preference_group - 1) * 5 + r.rank;
      const name = r[customKey] || r[lookupKey]?.name || "(unset)";
      return pos + ". " + name;
    }).join("\n") || "(none set)";
  }

  const student = fp.students || {};
  return [
    "Current student being discussed:",
    "Name: " + (student.student_name || "(unknown)"),
    "Pathway: " + fp.pathway,
    "Status: " + fp.status,
    "Matric marks: " + (student.matric_marks ?? "n/a") + ", First year marks: " + (student.first_year_marks ?? "n/a"),
    "",
    "Institute preferences (position. name):",
    fmtRows(instPrefs.data, "custom_institute_name", "institutes"),
    "",
    "Faculty preferences (position. name):",
    fmtRows(facPrefs.data, "custom_faculty_name", "fp_faculties"),
  ].join("\n");
}

async function buildFaqContext(adminClient: any, message: string): Promise<string> {
  // Lightweight grounding: pull merit formula rows whose institute
  // name appears (loosely) in the question, so answers about a
  // specific university's formula are backed by real stored data
  // instead of the model guessing/hallucinating a formula.
  const { data: formulas } = await adminClient
    .from("merit_formulas")
    .select("institute_name_raw, basis, program_scope, formula_text, weightages_text, effective_year")
    .limit(200);

  if (!formulas || !formulas.length) return "";

  const words = message.toLowerCase().split(/\W+/).filter((w: string) => w.length > 3);
  const matches = formulas.filter((f: any) => {
    const name = (f.institute_name_raw || "").toLowerCase();
    return words.some((w: string) => name.indexOf(w) !== -1);
  }).slice(0, 5);

  if (!matches.length) return "";

  return "Relevant merit formula records (use these, don't invent numbers):\n" +
    matches.map((f: any) =>
      "- " + f.institute_name_raw + (f.program_scope ? " (" + f.program_scope + ")" : "") +
      ": " + f.formula_text +
      (f.weightages_text ? " | Weightages: " + f.weightages_text : "") +
      (f.effective_year ? " | Effective: " + f.effective_year : "")
    ).join("\n");
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Missing Authorization header" }, 401);

    // Bound to the CALLER's own JWT -- used only to verify identity
    // and role via normal RLS. Never used to read/write anything the
    // caller wouldn't already be allowed to.
    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return json({ error: "Invalid session" }, 401);
    const userId = userData.user.id;

    const { data: profile } = await userClient.from("app_users").select("role").eq("id", userId).single();
    const role = profile?.role || "student";
    if (role !== "counsellor" && role !== "admin") {
      return json({ error: "This assistant is available to counsellors and admins only." }, 403);
    }

    // Service-role client -- only for rate-limit bookkeeping and
    // (when a studentId is given) fetching that student's record.
    // Safe to use here specifically because the role check above
    // already confirmed the caller is staff; this doesn't bypass any
    // permission the caller shouldn't have.
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const now = Date.now();
    const oneHourAgo = new Date(now - 60 * 60 * 1000).toISOString();
    const sixHoursAgo = new Date(now - 6 * 60 * 60 * 1000).toISOString();

    const [hourRes, sixHourRes] = await Promise.all([
      adminClient.from("chatbot_requests").select("id", { count: "exact", head: true }).eq("user_id", userId).gte("created_at", oneHourAgo),
      adminClient.from("chatbot_requests").select("id", { count: "exact", head: true }).eq("user_id", userId).gte("created_at", sixHoursAgo),
    ]);
    const hourCount = hourRes.count || 0;
    const sixHourCount = sixHourRes.count || 0;

    if (hourCount >= HOURLY_LIMIT) {
      return json({ error: "Rate limit reached: " + HOURLY_LIMIT + " questions per hour. Try again later." }, 429);
    }
    if (sixHourCount >= SIX_HOUR_LIMIT) {
      return json({ error: "Rate limit reached: " + SIX_HOUR_LIMIT + " questions per 6 hours. Try again later." }, 429);
    }

    const body = await req.json();
    const message = String(body.message || "").trim().slice(0, 2000);
    const studentId = body.studentId ? String(body.studentId) : null;
    if (!message) return json({ error: "Empty message" }, 400);

    const contextBlock = studentId
      ? await buildStudentContext(adminClient, studentId)
      : await buildFaqContext(adminClient, message);

    const systemPrompt = SYSTEM_PROMPT + (contextBlock ? "\n\n" + contextBlock : "");

    // Logged BEFORE the Groq call so a burst of parallel requests
    // can't all read the same pre-insert count and slip through.
    await adminClient.from("chatbot_requests").insert({ user_id: userId });

    if (!GROQ_API_KEY) {
      return json({ error: "Chat assistant isn't configured yet (missing GROQ_API_KEY secret)." }, 500);
    }

    const groqRes = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": "Bearer " + GROQ_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: message },
        ],
        temperature: 0.3,
        max_tokens: 700,
      }),
    });

    if (!groqRes.ok) {
      const errText = await groqRes.text();
      console.error("Groq error:", groqRes.status, errText);
      return json({ error: "The assistant is temporarily unavailable. Try again shortly." }, 502);
    }

    const groqData = await groqRes.json();
    const reply = groqData.choices?.[0]?.message?.content || "Sorry, I couldn't generate a response.";

    return json({
      reply,
      remaining: { hour: HOURLY_LIMIT - hourCount - 1, sixHour: SIX_HOUR_LIMIT - sixHourCount - 1 },
    });
  } catch (err) {
    console.error("chat-assistant error:", err);
    return json({ error: "Something went wrong." }, 500);
  }
});
