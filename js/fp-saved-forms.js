/* =========================================================
   fp-saved-forms.js — small "saved student forms" widget for
   counsellors/admins on the home dashboard (index.html).

   This is intentionally a lightweight glance: most-recent
   submissions + a read-only preview modal. The full table
   with filters, stats, and office-evaluation editing still
   lives in admin.html (js/fp-admin.js) — this widget links
   out to it rather than duplicating that functionality.
   Hidden entirely for role "student" (the default account
   role) since it exposes other people's data.
   ========================================================= */

window.FP = window.FP || {};

(function(){
  var DASH_LIMIT = 8;
  var lookups = { institutes:{}, faculties:{}, careers:{} };
  var submissions = [];
  var wired = false;

  /** Call after FP.requireAuth() resolves, passing the signed-in user's role. */
  FP.initSavedSubmissionsWidget = function(role){
    if(role !== "counsellor" && role !== "admin") return;

    var section = document.getElementById("fp-dash-section");
    if(!section) return;
    section.hidden = false;

    wireModalOnce();
    loadLookups().then(loadRecentSubmissions).catch(function(e){ console.error(e); });
  };

  function wireModalOnce(){
    if(wired) return;
    wired = true;
    document.getElementById("fpDashModalClose").addEventListener("click", closeModal);
    document.getElementById("fp-dash-modal-overlay").addEventListener("click", function(e){
      if(e.target.id === "fp-dash-modal-overlay") closeModal();
    });
  }

  function loadLookups(){
    return Promise.all([
      FP.client.from("institutes").select("id,name"),
      FP.client.from("fp_faculties").select("id,name"),
      FP.client.from("career_options").select("id,name")
    ]).then(function(r){
      (r[0].data||[]).forEach(function(x){ lookups.institutes[x.id] = x.name; });
      (r[1].data||[]).forEach(function(x){ lookups.faculties[x.id] = x.name; });
      (r[2].data||[]).forEach(function(x){ lookups.careers[x.id] = x.name; });
    });
  }

  function loadRecentSubmissions(){
    return FP.client.from("future_pathways").select("*, students(*)")
      .order("created_at", { ascending:false })
      .limit(DASH_LIMIT)
      .then(function(r){
        if(r.error){ console.error(r.error); return; }
        submissions = r.data || [];
        renderTable();
      });
  }

  function renderTable(){
    var tbody = document.getElementById("fp-dash-tbody");
    var empty = document.getElementById("fp-dash-empty");
    if(!submissions.length){
      tbody.innerHTML = "";
      empty.hidden = false;
      return;
    }
    empty.hidden = true;
    tbody.innerHTML = submissions.map(function(s){
      var name = titleCase((s.students && s.students.student_name) || "") || "(no profile yet)";
      return '<tr data-id="' + s.id + '">' +
        '<td>' + esc(name) + '</td>' +
        '<td class="fp-cap">' + esc(s.pathway) + '</td>' +
        '<td><span class="fp-badge ' + esc(s.status) + '">' + esc(s.status) + '</span></td>' +
        '<td>' + (s.created_at ? new Date(s.created_at).toLocaleDateString() : "\u2014") + '</td>' +
      '</tr>';
    }).join("");

    document.querySelectorAll("#fp-dash-tbody tr[data-id]").forEach(function(tr){
      tr.addEventListener("click", function(){ openPreview(tr.dataset.id); });
    });
  }

  function openPreview(id){
    var sub = submissions.find(function(s){ return s.id === id; });
    if(!sub) return;

    var overlay = document.getElementById("fp-dash-modal-overlay");
    var body = document.getElementById("fpDashModalBody");
    var title = document.getElementById("fpDashModalTitle");
    title.textContent = titleCase((sub.students && sub.students.student_name) || "") || "Student form preview";
    body.innerHTML = "<p>Loading\u2026</p>";
    overlay.hidden = false;

    Promise.all([
      FP.client.from("student_institute_preferences").select("*").eq("future_pathway_id", id),
      FP.client.from("student_faculty_preferences").select("*").eq("future_pathway_id", id),
      FP.client.from("student_program_preferences").select("*").eq("future_pathway_id", id)
    ]).then(function(r){
      renderPreview(sub, r[0].data||[], r[1].data||[], r[2].data||[]);
    }).catch(function(e){
      console.error(e);
      body.innerHTML = "<p>Could not load this form. See console for details.</p>";
    });
  }

  function closeModal(){
    document.getElementById("fp-dash-modal-overlay").hidden = true;
  }

  function groupedRows(rows, nameLookup){
    var byGroup = {};
    rows.forEach(function(r){
      byGroup[r.preference_group] = byGroup[r.preference_group] || [];
      byGroup[r.preference_group][r.rank-1] = r.custom_institute_name || r.custom_faculty_name ||
        nameLookup[r.institute_id || r.faculty_id] || "\u2014";
    });
    var groups = Object.keys(byGroup).sort();
    if(!groups.length) return '<div class="fp-review-row"><span>\u2014</span></div>';
    return groups.map(function(g){
      return '<div class="fp-review-row"><span>Group ' + g + '</span><span>' + byGroup[g].filter(Boolean).map(function(n,i){ return (i+1)+". "+esc(n); }).join(", ") + '</span></div>';
    }).join("");
  }

  function renderPreview(sub, instRows, facRows, progRows){
    var p = sub.students || {};
    var careerNames = progRows.map(function(r){ return r.custom_program_name || lookups.careers[r.program_id] || lookups.faculties[r.program_id] || null; }).filter(Boolean);

    var profileHtml = ["student_name","contact","discipline","matric_marks","first_year_marks"]
      .map(function(k){ return '<div class="fp-review-row"><span>' + k.replace(/_/g," ") + '</span><span>' + esc(p[k]) + '</span></div>'; }).join("");

    document.getElementById("fpDashModalBody").innerHTML =
      '<p class="fp-step-desc"><span class="fp-cap">' + esc(sub.pathway) + '</span> \u2014 <span class="fp-badge ' + esc(sub.status) + '">' + esc(sub.status) + '</span></p>' +
      '<div class="fp-review-section"><h4>Student information</h4>' + profileHtml + '</div>' +
      '<div class="fp-review-section"><h4>Programs &amp; careers</h4><div class="fp-review-row"><span>Selected</span><span>' + esc(careerNames.join(", ") || "\u2014") + '</span></div></div>' +
      '<div class="fp-review-section"><h4>Institute preferences</h4>' + groupedRows(instRows, lookups.institutes) + '</div>' +
      '<div class="fp-review-section"><h4>Faculty preferences</h4>' + groupedRows(facRows, lookups.faculties) + '</div>' +
      '<div class="fp-review-section"><h4>Additional information</h4><p>' + esc(sub.additional_information || "\u2014") + '</p></div>' +
      '<a href="admin.html" class="btn-secondary" style="display:inline-block; text-decoration:none; margin-top:8px;">Open in full admin view &rarr;</a>';
  }

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }

  // See js/fp-admin.js for the same helper + rationale (source data has
  // names in ALL CAPS; this is display-only, doesn't mutate stored data).
  function titleCase(s){
    return String(s || "").toLowerCase().replace(/\b\w/g, function(c){ return c.toUpperCase(); });
  }
})();
