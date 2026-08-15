/* =========================================================
   calculations.js — pure functions, no DOM here.
   ========================================================= */

window.Counsellor = window.Counsellor || {};

/**
 * Convert obtained/total marks into a percentage, clamped 0-100.
 */
Counsellor.toPercent = function toPercent(obtained, total){
  if(!total || total <= 0) return 0;
  const pct = (obtained / total) * 100;
  return Math.max(0, Math.min(100, pct));
};

/**
 * Compute a provisional aggregate score for a given field.
 * Only matric + FSc part 1 are known at this stage, so the
 * entry-test portion of the weight is left un-scored and
 * reported separately as "pending".
 *
 * Returns:
 *  {
 *    scoreSoFar:   weighted points earned out of 100 (test = 0)
 *    coveredWeight: matric weight + fsc weight (max score can currently be judged against)
 *    pendingWeight: weight still riding on the entry test
 *    provisionalPct: scoreSoFar expressed as % of coveredWeight (i.e. "how you're doing on what's measurable so far")
 *  }
 */
Counsellor.computeProvisionalScore = function computeProvisionalScore(fieldId, matricPct, fscPct){
  const weights = Counsellor.MERIT_WEIGHTS[fieldId] || { matric: 10, fsc: 90, test: 0 };

  const matricPoints = (matricPct / 100) * weights.matric;
  const fscPoints    = (fscPct / 100) * weights.fsc;
  const scoreSoFar    = matricPoints + fscPoints;
  const coveredWeight = weights.matric + weights.fsc;
  const pendingWeight  = weights.test;

  const provisionalPct = coveredWeight > 0 ? (scoreSoFar / coveredWeight) * 100 : 0;

  // Best-case ceiling: score so far plus the full pending (entry-test)
  // weight, as if that portion were scored 100% — capped at 100.
  const ceiling = Math.min(100, Math.round((scoreSoFar + pendingWeight) * 10) / 10);

  return {
    scoreSoFar: Math.round(scoreSoFar * 10) / 10,
    coveredWeight,
    pendingWeight,
    ceiling,
    provisionalPct: Math.round(provisionalPct * 10) / 10
  };
};
