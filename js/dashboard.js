/* =========================================================
   dashboard.js — landing page logic.

   index.html used to be a standalone "quick calculator" that
   re-asked for name + marks + field/area, then suggested
   universities — all of which duplicates the Future Pathways
   form (pathways.html) and the University Explorer
   (rankings.html). That form is gone; this page is now a
   dashboard: it reads the student's *existing* data (profile +
   Future Pathways status) straight from Supabase and tells them
   where they actually stand, with quick links into the three
   real tools. Nothing here re-collects marks or preferences.
   ========================================================= */

window.Dashboard = window.Dashboard || {};

(function(){

  var institutesLoadState = "loading"; // "loading" | "loaded" | "error"

  Dashboard.init = function init(authResult){
    var session = authResult.session;
    var profile = authResult.profile || {};
    var role = profile.role || "student";
    var studentId = session.user.id;

    renderGreeting(profile, role);

    if(role === "counsellor" || role === "admin"){
      // Counsellors/admins don't have a personal "case" — they work
      // many students' submissions (see the "Recently saved student
      // forms" section further down, js/fp-saved-forms.js). The
      // single draft/submitted status card below is a per-student
      // concept and doesn't apply to a staff account, so skip it
      // rather than showing a misleading "not started" for a case
      // that was never theirs to begin with.
      hideStatusSection();
    } else {
      loadStatus(studentId);
    }

    initUniModal();
    loadInstitutesWithLoadingState();

    if(typeof FP !== "undefined" && FP.loadMeritFormulas){
      FP.loadMeritFormulas().catch(function(err){ console.error("Merit formulas failed to load:", err); });
    }
  };

  /* ---------------------------------------------------------
     Greeting — uses the student's real name if we have one
     (app_users.full_name, falling back to the students row),
     never asks for it again. Never falls back to showing the
     account's email: full_name is sometimes left equal to the
     email (e.g. right after account creation, before a real
     name is set), and printing that as a large page headline
     is a confidentiality problem, not a personalization win.
     Counsellor/admin accounts get a role-based heading instead
     of a personal greeting, since this page isn't about them.
     --------------------------------------------------------- */
  function renderGreeting(profile, role){
    var heading = document.getElementById("dashGreeting");
    if(!heading) return;

    if(role === "counsellor" || role === "admin"){
      heading.textContent = "Dashboard";
      return;
    }

    var name = (profile.full_name || "").trim();
    var looksLikeEmail = name.indexOf("@") !== -1;
    heading.textContent = (name && !looksLikeEmail) ? "Welcome back, " + name.split(" ")[0] : "Welcome back";
  }

  function hideStatusSection(){
    var el = document.getElementById("dashStatus");
    if(el) el.hidden = true;
  }

  /* ---------------------------------------------------------
     Status card — pulls the student's `students` row (for a
     name fallback + marks-on-file check) and their latest
     `future_pathways` row (draft / submitted / none) and
     renders one clear, actionable card. Mirrors the query
     shapes already used by js/fp-app.js.
     --------------------------------------------------------- */
  function loadStatus(studentId){
    var el = document.getElementById("dashStatus");
    if(!el) return;

    Promise.all([
      FP.client.from("students").select("*").eq("id", studentId).maybeSingle(),
      FP.client.from("future_pathways").select("*")
        .eq("student_id", studentId)
        .order("created_at", { ascending: false })
        .limit(1).maybeSingle()
    ]).then(function(results){
      var studentRow = results[0].data;
      var pathwayRow = results[1].data;
      el.innerHTML = renderStatusCard(studentRow, pathwayRow);
    }).catch(function(err){
      console.error("Failed to load dashboard status:", err);
      el.innerHTML = '<div class="dash-status-card is-error">' +
        '<h2>Couldn\u2019t load case status</h2>' +
        '<p>Check your connection and reload this page. Saved data on the server is unaffected.</p>' +
        '</div>';
    });
  }

  function renderStatusCard(studentRow, pathwayRow){
    var status = pathwayRow ? pathwayRow.status : null;
    var hasMarks = !!(studentRow && studentRow.matric_marks && studentRow.first_year_marks);

    if(status === "submitted"){
      var stamp = pathwayRow.submitted_at ? new Date(pathwayRow.submitted_at) : null;
      var stampLabel = stamp ? stamp.toLocaleDateString(undefined, { year:"numeric", month:"long", day:"numeric" }) : "an earlier date";
      return '<div class="dash-status-card is-submitted">' +
        '<span class="dash-status-tag">Submitted</span>' +
        '<h2>Future Pathways application submitted.</h2>' +
        '<p>Submitted on ' + escapeHtml(stampLabel) + '. It\u2019s locked for editing &mdash; contact the admin office if something needs to change.</p>' +
        '<a class="btn-ghost dash-status-cta" href="pathways.html">Review submission</a>' +
        '</div>';
    }

    if(status === "draft"){
      return '<div class="dash-status-card is-draft">' +
        '<span class="dash-status-tag">Draft saved</span>' +
        '<h2>Continue this Future Pathways application.</h2>' +
        '<p>' + (hasMarks ? "Marks are already on file &mdash; " : "") + 'A draft is in progress. Continue where it left off; nothing is re-entered.</p>' +
        '<a class="btn-primary dash-status-cta" href="pathways.html">Continue application</a>' +
        '</div>';
    }

    return '<div class="dash-status-card is-empty">' +
      '<span class="dash-status-tag">Not started</span>' +
      '<h2>This Future Pathways application hasn\u2019t been started yet.</h2>' +
      '<p>The official counselling submission &mdash; marks, ranked institute and faculty preferences, reviewed by staff.</p>' +
      '<a class="btn-primary dash-status-cta" href="pathways.html">Start the form</a>' +
      '</div>';
  }

  /* ---------------------------------------------------------
     "View all universities" modal — unchanged from the old
     calculator page: groups the live Counsellor.INSTITUTES
     (loaded from Supabase) by their `pathway` column.
     --------------------------------------------------------- */
  function loadInstitutesWithLoadingState(){
    institutesLoadState = "loading";
    return Counsellor.loadInstitutes().then(function(){
      institutesLoadState = "loaded";
    }).catch(function(err){
      institutesLoadState = "error";
      console.error("Failed to load institutes from Supabase:", err);
    });
  }

  function initUniModal(){
    var openBtn  = document.getElementById("viewUnisBtn");
    var overlay  = document.getElementById("uniModalOverlay");
    var closeBtn = document.getElementById("uniModalClose");
    var body      = document.getElementById("uniModalBody");
    if(!openBtn || !overlay || !closeBtn || !body) return;

    function open(){
      body.innerHTML = renderUniGroups();
      overlay.hidden = false;
      document.addEventListener("keydown", onKeydown);

      if(institutesLoadState !== "loaded"){
        loadInstitutesWithLoadingState().then(function(){
          if(!overlay.hidden) body.innerHTML = renderUniGroups();
        });
      }
    }
    function close(){
      overlay.hidden = true;
      document.removeEventListener("keydown", onKeydown);
    }
    function onKeydown(e){ if(e.key === "Escape") close(); }

    openBtn.addEventListener("click", open);
    closeBtn.addEventListener("click", close);
    overlay.addEventListener("click", function(e){
      if(e.target === overlay) close();
    });
    body.addEventListener("click", function(e){
      if(!e.target.classList.contains("merit-toggle")) return;
      var instName = e.target.dataset.inst;
      var container = e.target.closest("li").querySelector(".merit-inline-container");
      var isOpen = !container.hidden;
      if(isOpen){
        container.hidden = true;
        e.target.textContent = "View merit formula";
        return;
      }
      container.innerHTML = FP.renderMeritSectionForInstitute(instName);
      container.hidden = false;
      e.target.textContent = "Hide merit formula";
    });
  }

  function renderUniGroups(){
    if(institutesLoadState === "loading"){
      return '<p class="uni-modal-empty">Loading universities from the database\u2026</p>';
    }
    if(institutesLoadState === "error"){
      return '<p class="uni-modal-empty">Couldn\u2019t load universities from the database. Check your connection and try reopening this window.</p>';
    }

    var all = Counsellor.INSTITUTES || [];
    if(all.length === 0){
      return '<p class="uni-modal-empty">No universities are in the database yet. Run the seed script in Supabase, then reopen this window.</p>';
    }

    var buckets = { "Engineering": [], "Medical": [], "Other": [] };

    all.forEach(function(inst){
      var bucket = inst.pathway === "engineering" ? "Engineering"
                 : inst.pathway === "medical"      ? "Medical"
                 : "Other";
      buckets[bucket].push(inst);
    });

    var order = ["Engineering", "Medical", "Other"];
    return order
      .filter(function(name){ return name !== "Other" || buckets["Other"].length > 0; })
      .map(function(name){
        var entries = buckets[name];
        var listHtml = entries.length
          ? "<ul>" + entries.map(function(inst){
              var meta = inst.location || (inst.campuses && inst.campuses.length ? inst.campuses.join(", ") : "");
              return "<li><div class=\"uni-modal-row\"><span>" + escapeHtml(inst.name) + "</span>" +
                     "<span class=\"uni-modal-programs\">" + escapeHtml(meta) + "</span>" +
                     "<button type=\"button\" class=\"merit-toggle\" data-inst=\"" + escapeHtml(inst.name) + "\">View merit formula</button></div>" +
                     "<div class=\"merit-inline-container\" hidden></div></li>";
            }).join("") + "</ul>"
          : "<p class=\"uni-modal-empty\">No universities listed yet.</p>";

        return "<div class=\"uni-modal-group\"><h3>" + name + " (" + entries.length + ")</h3>" + listHtml + "</div>";
      }).join("");
  }

  function escapeHtml(str){
    return String(str).replace(/[&<>"']/g, function(c){
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;" }[c];
    });
  }

})();
