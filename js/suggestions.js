/* =========================================================
   suggestions.js — turns (student + Counsellor.INSTITUTES)
   into a ranked list of institute suggestions. Institute data
   is loaded live from Supabase (see Counsellor.loadInstitutes
   in js/data.js) rather than a static array.

   Note: the real `institutes` table has no per-institute
   program/closing-merit linkage (that only existed in the old
   static placeholder data), so a "suggestion" here is one row
   per matching institute, not per program. Merit scoring is
   still computed from the student's marks (for the score strip)
   but institutes are never ranked/filtered by it while
   Counsellor.MERIT_FEATURE_ENABLED is false.
   ========================================================= */

window.Counsellor = window.Counsellor || {};

const STATUS_RANK = { strong: 0, competitive: 1, unknown: 2, unlikely: 3 };

/**
 * Decide how a student's provisional score compares to a
 * closing merit.
 *   strong      — already clears the merit without the entry test
 *   competitive — reachable depending on entry-test performance
 *   unlikely    — out of reach even with a perfect entry test
 *   unknown     — no closing merit on file yet, OR the merit
 *                 feature is temporarily disabled (see data.js)
 */
function classify(scoreSoFar, pendingWeight, closingMerit){
  if(!Counsellor.MERIT_FEATURE_ENABLED) return "unknown";
  if(closingMerit === null || closingMerit === undefined) return "unknown";
  const ceiling = scoreSoFar + pendingWeight;
  if(scoreSoFar >= closingMerit) return "strong";
  if(ceiling < closingMerit)      return "unlikely";
  return "competitive";
}

/**
 * True if the institute's location/campuses mention the
 * student's preferred area. "any" always matches. Institutes
 * with neither a location nor campuses on file (true today for
 * every medical institute in the seed data) never match a
 * specific area — they'll surface under "Outside your
 * preferred area" until location data is added for them.
 */
function isAreaMatch(institute, areaId){
  if(areaId === "any") return true;
  const haystack = [institute.location || ""].concat(institute.campuses || []).join(" ").toLowerCase();
  return haystack.indexOf(areaId) !== -1;
}

/**
 * @param {Object} student
 *   { name, matricPct, fscPct, fieldId, areaId }
 * @returns {Array} ranked list of suggestion objects
 */
Counsellor.getSuggestions = function getSuggestions(student){
  const pathway = Counsellor.FIELD_TO_PATHWAY[student.fieldId];
  const results = [];

  const { scoreSoFar, pendingWeight } =
    Counsellor.computeProvisionalScore(student.fieldId, student.matricPct, student.fscPct);

  (Counsellor.INSTITUTES || []).forEach(function(inst){
    if(inst.pathway !== pathway) return;

    results.push({
      universityId: inst.id,
      universityName: inst.name,
      category: inst.category,
      location: inst.location || (inst.campuses && inst.campuses.length ? inst.campuses.join(", ") : null),
      closingMerit: null,
      scoreSoFar: scoreSoFar,
      ceiling: Math.round((scoreSoFar + pendingWeight) * 10) / 10,
      status: classify(scoreSoFar, pendingWeight, null),
      isAreaMatch: isAreaMatch(inst, student.areaId)
    });
  });

  results.sort(function(a, b){
    if(a.isAreaMatch !== b.isAreaMatch) return a.isAreaMatch ? -1 : 1;
    if(!Counsellor.MERIT_FEATURE_ENABLED) return a.universityName.localeCompare(b.universityName);
    if(STATUS_RANK[a.status] !== STATUS_RANK[b.status]) return STATUS_RANK[a.status] - STATUS_RANK[b.status];
    return b.scoreSoFar - a.scoreSoFar;
  });

  return results;
};
