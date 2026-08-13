import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * Handles Supabase's redirect-based auth flows (email confirmation links,
 * magic links, OAuth) by exchanging the ?code= for a session, then
 * redirecting into the app.
 */
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/student/dashboard";

  if (code) {
    const supabase = createClient();
    await supabase.auth.exchangeCodeForSession(code);
  }

  return NextResponse.redirect(`${origin}${next}`);
}
