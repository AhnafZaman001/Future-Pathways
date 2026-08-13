import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export default async function AdminDashboardPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  // Only accounts explicitly provisioned with role="admin" in app_metadata
  // (via the Supabase Admin API, never via self-signup) may reach this page.
  if (user.app_metadata?.role !== "admin") {
    redirect("/student/dashboard");
  }

  return (
    <main className="mx-auto max-w-4xl px-6 py-12">
      <h1 className="text-2xl font-bold">Admin dashboard</h1>
      <p className="mt-1 text-sm text-slate-600">Signed in as {user.email}</p>

      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        <ShellCard
          title="Universities & programs"
          description="Manage the institutional catalog and program offerings."
        />
        <ShellCard
          title="Admissions data"
          description="Requirements, merit history, fees, and deadlines."
        />
        <ShellCard
          title="Questionnaire"
          description="Manage assessment questions, options, and rules."
        />
        <ShellCard
          title="Data provenance"
          description="Sources and verification records."
        />
      </div>

      <p className="mt-10 text-sm text-slate-400">
        This is a foundation shell — these sections are not yet built.
      </p>
    </main>
  );
}

function ShellCard({
  title,
  description,
}: {
  title: string;
  description: string;
}) {
  return (
    <div className="rounded-lg border border-slate-200 p-5">
      <h2 className="font-semibold">{title}</h2>
      <p className="mt-1 text-sm text-slate-600">{description}</p>
    </div>
  );
}
