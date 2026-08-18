/* =========================================================
   merit-calculator-data.js — the actual per-university weighted
   formulas driving the interactive calculator. Distinct from
   merit_formulas (the Supabase-backed Merit & Entry Test Guide,
   which is informational/read-only text) -- this data feeds a
   real client-side computation.

   Every formula below is sourced from Parhlai's or UniCalc's own
   merit calculators (both cited by name when this feature was
   requested) and, where those two sources disagreed with each
   other or with earlier research in this project, cross-checked
   against a third source before being used here. See the `notes`
   field on each entry for anything that needed that extra check.

   field.type:
     "percent" — direct 0-100 input, used as-is
     "marks"   — obtained/maxMarks input, converted to a
                 percentage before applying its weight
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
      { key: "ssc",  label: "Matric / SSC percentage", type: "percent", weight: 10 },
      { key: "hssc", label: "FSc / HSSC percentage",    type: "percent", weight: 15 },
      { key: "test", label: "NET score",                type: "marks",   weight: 75, maxMarks: 200 }
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
      { key: "ssc",  label: "SSC / O-Level equivalence percentage",  type: "percent", weight: 10 },
      { key: "hssc", label: "HSSC / A-Level equivalence percentage", type: "percent", weight: 40 },
      { key: "test", label: "FAST admission test percentage",        type: "percent", weight: 50 }
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
      { key: "ssc",  label: "SSC / O-Level equivalence percentage",  type: "percent", weight: 17 },
      { key: "hssc", label: "HSSC / A-Level equivalence percentage", type: "percent", weight: 50 },
      { key: "test", label: "FAST admission test percentage",        type: "percent", weight: 33 }
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
      { key: "ssc",  label: "Matric / SSC percentage", type: "percent", weight: 15 },
      { key: "test", label: "GIKI entry test score",    type: "marks",   weight: 85, maxMarks: 200 }
    ],
    notes: "The first source pulled for this page showed \u201c10% Matric + 85% Test\u201d, which only sums to 95% \u2014 a sign something was mis-scraped, not a real formula. Cross-checked against ilmkidunya.com and CampusAxis, both independently confirming 15% + 85%. FSc/Intermediate marks are an eligibility requirement (60% minimum) but are explicitly NOT weighted in GIKI's merit formula \u2014 don't be surprised there's no FSc field here."
  },
  {
    id: "pieas",
    university: "PIEAS",
    variantLabel: "Undergraduate",
    formulaText: "15% SSC + 25% HSSC Part-I + 60% Official Test Percentile",
    sourceUrl: "https://parhlai.com/merit-calculator/pieas",
    sourceLabel: "Parhlai \u2014 PIEAS Merit Calculator",
    fields: [
      { key: "ssc",  label: "SSC percentage",                              type: "percent", weight: 15 },
      { key: "hssc", label: "HSSC Part-I percentage",                      type: "percent", weight: 25 },
      { key: "test", label: "Official PIEAS percentile (not raw marks)",   type: "percent", weight: 60 }
    ],
    notes: "Enter the official percentile PIEAS itself issues \u2014 raw test marks can't be converted into it. NAT is not accepted for this calculation; if you took NAT instead of PIEAS's own test, this formula doesn't apply to you."
  },
  {
    id: "uet",
    university: "UET",
    variantLabel: "ECAT-based engineering",
    formulaText: "10% Matric + 40% Intermediate + 50% Entry Test",
    sourceUrl: "https://unicalc.csconnect.pk/uet/",
    sourceLabel: "UniCalc \u2014 UET Aggregate Calculator",
    fields: [
      { key: "ssc",  label: "Matric percentage",                         type: "percent", weight: 10 },
      { key: "hssc", label: "Intermediate (FSc Part-I) percentage",      type: "percent", weight: 40 },
      { key: "test", label: "Entry test percentage (ECAT / NAT / SAT)",  type: "percent", weight: 50 }
    ],
    notes: "\u201cUET\u201d covers multiple campuses (Lahore, Taxila, Peshawar) whose formulas can differ slightly by campus and by year \u2014 this is UniCalc's general UET figure. Verify against your specific campus's current admission notice before treating this as exact."
  }
];
