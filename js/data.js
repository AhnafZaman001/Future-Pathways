/* =========================================================
   data.js — static reference data + the Supabase institute
   loader. As of the index.html/Supabase switchover, the old
   static Counsellor.UNIVERSITIES placeholder array is GONE —
   institute data now comes live from the real `institutes`
   table (86 seeded rows) via Counsellor.loadInstitutes(),
   the same table pathways.html already reads through
   FP.client (see js/fp-client.js).
   ========================================================= */

window.Counsellor = window.Counsellor || {};

/* -----------------------------------------------------------
   TEMPORARY KILL-SWITCH — set to true once real, sourced
   closing-merit data (see the planned `merit_records` table)
   and per-university formulas are loaded. While false: every
   institute shows as "Merit data pending" (no Strong/
   Competitive/Unlikely badge, no gauge score), and the results
   list is NOT sorted/reordered by merit chance — it just
   follows field + area match. Flip to true when ready; nothing
   else needs to change.
   ----------------------------------------------------------- */
Counsellor.MERIT_FEATURE_ENABLED = false;

/* -----------------------------------------------------------
   FIELDS — trimmed to what the real Supabase data actually
   supports. institutes.pathway only has two values:
   'engineering' and 'medical'. There is no institute-level
   program/faculty linkage table, so "Engineering" and
   "Computer Science / IT" both resolve to the same set of
   engineering-pathway institutes (the CS/IT vs. other-major
   split lives in fp_faculties, not on individual institutes).
   business/social/arts/natural were removed — there is no
   institute data for those pathways in Supabase at all.
   ----------------------------------------------------------- */
Counsellor.FIELDS = [
  { id: "engineering",  label: "Engineering" },
  { id: "cs",            label: "Computer Science / IT" },
  { id: "medical",      label: "Medical (MBBS/BDS)" }
];

/* Maps a Counsellor.FIELDS id to the institutes.pathway value
   used to filter the live Supabase query. */
Counsellor.FIELD_TO_PATHWAY = {
  engineering: "engineering",
  cs:          "engineering",
  medical:      "medical"
};

Counsellor.AREAS = [
  { id: "islamabad", label: "Islamabad" },
  { id: "rawalpindi", label: "Rawalpindi" },
  { id: "lahore",      label: "Lahore" },
  { id: "karachi",    label: "Karachi" },
  { id: "peshawar",    label: "Peshawar" },
  { id: "multan",      label: "Multan" },
  { id: "faisalabad", label: "Faisalabad" },
  { id: "any",        label: "No preference / anywhere" }
];

/* Human-readable labels for institutes.category (institute
   subtype, distinct from pathway). Used only for display. */
Counsellor.CATEGORY_LABELS = {
  engineering: "Engineering institute",
  medical:      "Government medical college",
  nums:        "NUMS-affiliated college",
  private:      "Private medical college",
  other:        "AKU / other medical"
};

/* Merit formula weights per field, as % of total 100.
   "test" is the entry-test / interview component that isn't
   available at intake time — its weight is shown to the user
   as "pending" rather than scored as zero.
   TODO: tune these per real admission criteria per field. */
Counsellor.MERIT_WEIGHTS = {
  engineering: { matric: 10, fsc: 40, test: 50 },
  cs:          { matric: 10, fsc: 40, test: 50 },
  medical:      { matric: 10, fsc: 50, test: 40 }
};

/* -----------------------------------------------------------
   Counsellor.INSTITUTES — populated at runtime from Supabase
   by Counsellor.loadInstitutes(). Empty until that resolves.
   Shape of each row matches the `institutes` table: id, name,
   category, location, campuses (text[]), pathway, active,
   display_order.
   ----------------------------------------------------------- */
Counsellor.INSTITUTES = [];

/**
 * Loads all active institutes from Supabase into
 * Counsellor.INSTITUTES. Requires FP.client (js/fp-client.js)
 * to already be initialized. Safe to call more than once —
 * each call re-fetches and replaces the cached list.
 * @returns {Promise<Array>}
 */
Counsellor.loadInstitutes = function loadInstitutes(){
  if(typeof window.FP === "undefined" || !window.FP.client){
    return Promise.reject(new Error("FP.client not available — js/fp-client.js must load first."));
  }
  return FP.client.from("institutes").select("*").eq("active", true).order("display_order")
    .then(function(r){
      if(r.error) throw r.error;
      Counsellor.INSTITUTES = r.data || [];
      return Counsellor.INSTITUTES;
    });
};
