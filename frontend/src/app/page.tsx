import Link from "next/link";

export default function LandingPage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col justify-center px-6">
      <div className="max-w-2xl">
        <p className="mb-3 text-sm font-medium uppercase tracking-wide text-indigo-600">
          Future Pathways
        </p>
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          Find the programs, universities, and careers that actually fit you.
        </h1>
        <p className="mt-6 text-lg text-slate-600">
          Answer a short adaptive questionnaire, add your academic record,
          and get personalized Safe / Target / Reach recommendations —
          with real eligibility rules, historical closing merit, fees, and
          deadlines.
        </p>
        <div className="mt-8 flex gap-4">
          <Link
            href="/signup"
            className="rounded-md bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Get started
          </Link>
          <Link
            href="/login"
            className="rounded-md px-5 py-2.5 text-sm font-semibold text-slate-900 ring-1 ring-inset ring-slate-300 hover:bg-slate-50"
          >
            Log in
          </Link>
        </div>
      </div>
    </main>
  );
}
