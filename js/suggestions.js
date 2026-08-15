/* =========================================================
   suggestions.js — turns (student + Counsellor.UNIVERSITIES)
   into a ranked list of program suggestions.
   ========================================================= */

window.Counsellor = window.Counsellor || {};

const STATUS_RANK = { strong: 0, competitive: 1, unknown: 2, unlikely: 3 };

/**
 * Decide how a student's provisional score compares to a
 * program's closing merit.
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
 * @param {Object} student
 *   { name, matricPct, fscPct, fieldId, areaId }
 * @returns {Array} ranked list of suggestion objects
 */
Counsellor.getSuggestions = function getSuggestions(student){
  const results = [];

  Counsellor.UNIVERSITIES.forEach(function(uni){
    uni.programs.forEach(function(program){
      if(program.field !== student.fieldId) return;

      const { scoreSoFar, pendingWeight } =
        Counsellor.computeProvisionalScore(student.fieldId, student.matricPct, student.fscPct);

      const status = classify(scoreSoFar, pendingWeight, program.closingMerit);
      const isAreaMatch = student.areaId === "any" || uni.area === student.areaId;

      results.push({
        universityId: uni.id,
        universityName: uni.name,
        area: uni.area,
        programName: program.programName,
        closingMerit: program.closingMerit,
        scoreSoFar: scoreSoFar,
        ceiling: Math.round((scoreSoFar + pendingWeight) * 10) / 10,
        status: status,
        isAreaMatch: isAreaMatch
      });
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
