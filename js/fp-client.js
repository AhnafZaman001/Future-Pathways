/* =========================================================
   fp-client.js — shared Supabase client for the Future
   Pathways form + admin pages. Uses the publishable (anon)
   key; no login required. Each browser gets a random,
   persistent anonymous ID (localStorage) that is used as the
   student's row identifier, so a return visit on the same
   device/browser resumes their draft automatically.
   ========================================================= */

window.FP = window.FP || {};

(function(){
  var SUPABASE_URL = "https://sqaehbedobvvannzqbow.supabase.co";
  var SUPABASE_ANON_KEY = "sb_publishable_iJ9vEuA-0mBCKYpLOOr2YQ_k4zy5rVb";
  var ANON_ID_KEY = "fp_anon_student_id";

  if(typeof window.supabase === "undefined"){
    console.error("Supabase JS library did not load — check your internet connection.");
    return;
  }

  var client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  FP.client = client;

  function uuidv4(){
    if(window.crypto && window.crypto.randomUUID) return window.crypto.randomUUID();
    // Fallback for older browsers.
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c){
      var r = Math.random() * 16 | 0, v = c === "x" ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  /** Returns this browser's anonymous student id, creating and storing one on first visit. */
  FP.getAnonId = function(){
    var id = null;
    try { id = window.localStorage.getItem(ANON_ID_KEY); } catch(e){ /* storage unavailable */ }
    if(!id){
      id = uuidv4();
      try { window.localStorage.setItem(ANON_ID_KEY, id); } catch(e){ /* storage unavailable */ }
    }
    return id;
  };
})();
