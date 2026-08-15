/* =========================================================
   supabase-client.js — used only for saveSubmission(). Reuses
   the single Supabase client created in js/fp-client.js
   (FP.client) rather than creating a second client instance.
   Two separate clients against the same project both run their
   own background auth-refresh/session-lock logic, and contend
   for the same browser storage lock — this was the actual
   cause of the page-wide input lag (clicks/typing/dropdowns
   feeling sluggish, needing multiple tries).
   ========================================================= */

window.Counsellor = window.Counsellor || {};

(function(){
  if(typeof window.FP === "undefined" || !window.FP.client){
    console.warn("FP.client not available — make sure js/fp-client.js is loaded before js/supabase-client.js. Submissions will not be saved to the database.");
    Counsellor.saveSubmission = function(){
      return Promise.resolve({ error: new Error("Supabase client not initialized") });
    };
    return;
  }

  var client = window.FP.client;

  /**
   * Insert one student submission row.
   * @param {Object} record — snake_case keys matching supabase/schema.sql
   * @returns {Promise<{ data, error }>}
   */
  Counsellor.saveSubmission = function(record){
    return client.from("student_submissions").insert([record]).then(function(result){
      if(result.error){
        console.error("Supabase insert failed:", result.error);
      } else {
        console.log("Supabase insert succeeded:", result);
      }
      return result;
    });
  };
})();
