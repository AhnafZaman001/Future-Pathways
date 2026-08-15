/* =========================================================
   supabase-client.js — the only file that talks to Supabase.
   Uses the PUBLISHABLE (anon) key, which is safe to ship in
   client-side code — it can only do what the RLS policies in
   supabase/schema.sql allow (insert-only, see that file).
   ========================================================= */

window.Counsellor = window.Counsellor || {};

(function(){
  var SUPABASE_URL = "https://sqaehbedobvvannzqbow.supabase.co";
  var SUPABASE_ANON_KEY = "sb_publishable_iJ9vEuA-0mBCKYpLOOr2YQ_k4zy5rVb";

  if(typeof window.supabase === "undefined"){
    console.warn("Supabase JS library did not load — check your internet connection. Submissions will not be saved to the database.");
    Counsellor.saveSubmission = function(){
      return Promise.resolve({ error: new Error("Supabase library not loaded") });
    };
    return;
  }

  var client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  /**
   * Insert one student submission row.
   * @param {Object} record — snake_case keys matching supabase/schema.sql
   * @returns {Promise<{ data, error }>}
   */
  Counsellor.saveSubmission = function(record){
    return client.from("student_submissions").insert([record]);
  };
})();
