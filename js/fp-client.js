/* =========================================================
   fp-client.js — shared Supabase client for the Future
   Pathways form + admin pages. Uses the same publishable
   (anon) key as js/supabase-client.js; all real access
   control happens via RLS (see supabase/future_pathways_schema.sql),
   this key is safe to ship client-side.
   ========================================================= */

window.FP = window.FP || {};

(function(){
  var SUPABASE_URL = "https://sqaehbedobvvannzqbow.supabase.co";
  var SUPABASE_ANON_KEY = "sb_publishable_iJ9vEuA-0mBCKYpLOOr2YQ_k4zy5rVb";

  if(typeof window.supabase === "undefined"){
    console.error("Supabase JS library did not load — check your internet connection.");
    return;
  }

  var client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: true, autoRefreshToken: true }
  });

  FP.client = client;

  FP.getSession = function(){
    return client.auth.getSession().then(function(r){ return r.data.session; });
  };

  FP.signUp = function(email, password, fullName){
    return client.auth.signUp({
      email: email,
      password: password,
      options: { data: { full_name: fullName } }
    });
  };

  FP.signIn = function(email, password){
    return client.auth.signInWithPassword({ email: email, password: password });
  };

  FP.signOut = function(){
    return client.auth.signOut();
  };

  /** Require a logged-in session; redirect to auth.html (preserving the page the user asked for) if missing. */
  FP.requireAuth = function(){
    return FP.getSession().then(function(session){
      if(!session){
        var here = window.location.pathname.split("/").pop() || "index.html";
        window.location.href = "auth.html?next=" + encodeURIComponent(here);
        return null;
      }
      return session;
    });
  };

  FP.getMyRole = function(userId){
    return client.from("app_users").select("role").eq("id", userId).single()
      .then(function(r){ return r.data ? r.data.role : "student"; });
  };
})();
