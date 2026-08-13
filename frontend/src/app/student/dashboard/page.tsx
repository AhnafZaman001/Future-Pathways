import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export default async function StudentDashboardPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  // Admins land on their own dashboard, not this one.
  if (user.app_metadata?.role === "admin") {
    redirect("/admin/dashboard");
  }

  return (
    <main className="mx-auto max-w-4xl px-6 py-12">
      <h1 className="text-2xl font-bold">Your dashboard</h1>
      <p className="mt-1 text-sm text-slate-600">Signed in as {user.email}</p>

      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        <ShellCard
          title="Academic profile"
          description="Add your qualifications, subjects, and test scores."
        />
        <ShellCard
          title="Questionnaire"
          description="Answer the adaptive career & preference questionnaire."
        />
        <ShellCard
          title="Recommendations"
          description="See your Safe / Target / Reach program recommendations."
        />
        <ShellCard
          title="Saved"
          description="Universities and programs you've bookmarked."
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
