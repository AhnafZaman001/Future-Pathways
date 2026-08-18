/* =========================================================
   merit-calculator-data.js — the per-university weighted formulas
   driving the interactive calculator. Distinct from merit_formulas
   (the Supabase-backed Merit & Entry Test Guide, informational/
   read-only text) -- this data feeds a real client-side computation.

   sourceUrl/sourceLabel are kept here for internal maintainability
   (so a future update knows where a formula came from) but are
   NOT rendered in the UI -- this is our calculator, not a
   wrapper around someone else's. Cite sources where it's actually
   load-bearing for the reader (the University Explorer / Merit
   Guide pages, where methodology and confidence genuinely matter)
   -- not on a plug-in-your-marks tool where it just reads as
   pointing at another site's calculator. See PROGRESS.md.

   field.type:
     "percent"        — direct 0-100 input, used as-is. For
                         components that ARE already a percentage
                         with no natural "out of" total (a test
                         percentage/percentile).
     "marks_fixed"     — obtained out of a FIXED, universally-known
                         total (e.g. NUST NET and GIKI's test are
                         both out of 200 for everyone) -- one input.
     "marks_variable"  — obtained AND total, both entered by the
                         student -- used for Matric/SSC and FSc/HSSC,
                         since total marks vary by board. Percentage
                         is computed from these, never asked for
                         directly.
   ========================================================= */

window.MERIT_CALCULATORS = [
  {
    id: "nust_net",
    university: "NUST",
    variantLabel: "NET-basis (most common route)",
    formulaText: "75% NET + 15% HSSC + 10% SSC",
    sourceUrl: "https://parhlai.com/merit-calculator/nust",
    sourceLabel: "Parhlai \u2014 NUST Merit Calculator",
    fields: [
      { key: "ssc",  label: "Matric / SSC marks",  type: "marks_variable", weight: 10 },
      { key: "hssc", label: "FSc / HSSC marks",     type: "marks_variable", weight: 15 },
      { key: "test", label: "NET score",            type: "marks_fixed",    weight: 75, maxMarks: 200 }
    ],
    notes: "NUST also has a separate ACT/SAT-basis route (same weights, applied to an ACT/SAT score instead of NET) \u2014 not covered here yet, since ACT/SAT use a different scale (36 / 1600) that would need its own conversion, not just a different max."
  },
  {
    id: "fast_computing_business",
    university: "FAST-NUCES",
    variantLabel: "Computing or Business",
    formulaText: "10% SSC + 40% HSSC + 50% Admission Test",
    sourceUrl: "https://parhlai.com/merit-calculator/fast",
    sourceLabel: "Parhlai \u2014 FAST-NUCES Merit Calculator",
    fields: [
      { key: "ssc",  label: "SSC / O-Level marks",           type: "marks_variable", weight: 10 },
      { key: "hssc", label: "HSSC / A-Level marks",          type: "marks_variable", weight: 40 },
      { key: "test", label: "FAST admission test percentage", type: "percent",        weight: 50 }
    ]
  },
  {
    id: "fast_engineering",
    university: "FAST-NUCES",
    variantLabel: "Engineering",
    formulaText: "17% SSC + 50% HSSC + 33% Admission Test",
    sourceUrl: "https://parhlai.com/merit-calculator/fast",
    sourceLabel: "Parhlai \u2014 FAST-NUCES Merit Calculator",
    fields: [
      { key: "ssc",  label: "SSC / O-Level marks",            type: "marks_variable", weight: 17 },
      { key: "hssc", label: "HSSC / A-Level marks",           type: "marks_variable", weight: 50 },
      { key: "test", label: "FAST admission test percentage",  type: "percent",        weight: 33 }
    ],
    notes: "Engineering uses a different split from Computing/Business at the same university \u2014 double-check which one applies to your program."
  },
  {
    id: "giki",
    university: "GIKI",
    variantLabel: "Undergraduate",
    formulaText: "15% Matric / last completed qualification + 85% Admission Test",
    sourceUrl: "https://parhlai.com/merit-calculator/giki",
    sourceLabel: "Parhlai \u2014 GIKI Merit Calculator",
    fields: [
      { key: "ssc",  label: "Matric / SSC marks",   type: "marks_variable", weight: 15 },
      { key: "test", label: "GIKI entry test score", type: "marks_fixed",    weight: 85, maxMarks: 200 }
    ],
    notes: "FSc/Intermediate marks are an eligibility requirement (60% minimum) but are not weighted in GIKI's merit formula \u2014 that's why there's no FSc field here."
  },
  {
    id: "pieas",
    university: "PIEAS",
    variantLabel: "Undergraduate",
    formulaText: "15% SSC + 25% HSSC Part-I + 60% Official Test Percentile",
    sourceUrl: "https://parhlai.com/merit-calculator/pieas",
    sourceLabel: "Parhlai \u2014 PIEAS Merit Calculator",
    fields: [
      { key: "ssc",  label: "SSC marks",                                   type: "marks_variable", weight: 15 },
      { key: "hssc", label: "HSSC Part-I marks",                          type: "marks_variable", weight: 25 },
      { key: "test", label: "Official PIEAS percentile (not raw marks)",  type: "percent",         weight: 60 }
    ],
    notes: "Enter the official percentile PIEAS itself issues \u2014 raw test marks can't be converted into it. NAT is not accepted for this calculation."
  },
  {
    id: "uet",
    university: "UET",
    variantLabel: "ECAT-based engineering",
    formulaText: "10% Matric + 40% Intermediate + 50% Entry Test",
    sourceUrl: "https://unicalc.csconnect.pk/uet/",
    sourceLabel: "UniCalc \u2014 UET Aggregate Calculator",
    fields: [
      { key: "ssc",  label: "Matric marks",                             type: "marks_variable", weight: 10 },
      { key: "hssc", label: "Intermediate (FSc Part-I) marks",          type: "marks_variable", weight: 40 },
      { key: "test", label: "Entry test percentage (ECAT / NAT / SAT)", type: "percent",         weight: 50 }
    ],
    notes: "\u201cUET\u201d covers multiple campuses (Lahore, Taxila, Peshawar) whose formulas can differ slightly by campus and by year \u2014 verify against your specific campus's current admission notice."
  }
];
