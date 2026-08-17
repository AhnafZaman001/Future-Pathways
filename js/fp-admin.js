/* =========================================================
   fp-admin.js — counsellor/admin view of Future Pathways
   submissions. RLS on the tables enforces access server-side;
   this client-side gate only avoids showing a confusing blank
   page to students who land here by mistake.
   ========================================================= */

(function(){
  var submissions = [];
  var lookups = { institutes:{}, faculties:{}, careers:{} };
  var firstPriorityByFpId = {}; // future_pathway_id -> institute name (or custom name)

  // Fire every network request immediately, in parallel with the auth
  // check -- RLS enforces access server-side regardless of when the
  // client-side profile fetch resolves, so there's no correctness reason
  // to make these wait on each other. Previously this was four fully
  // sequential round-trips (auth -> lookups -> first-priorities ->
  // submissions); now it's one round-trip's worth of latency, not four.
  var authPromise = FP.getSessionAndProfile();
  var institutesPromise = FP.client.from("institutes").select("id,name").order("name");
  var facultiesPromise  = FP.client.from("fp_faculties").select("id,name");
  var careersPromise    = FP.client.from("career_options").select("id,name");
  var firstPrioPromise  = FP.client.from("student_institute_preferences")
    .select("future_pathway_id, institute_id, custom_institute_name")
    .eq("preference_group", 1).eq("rank", 1);
  var submissionsPromise = FP.client.from("future_pathways").select("*, students(*)").order("created_at", { ascending:false });

  authPromise.then(function(result){
    if(!result){ window.location.href = "login.html"; return; } // requireAuth's redirect, inlined

    var role = result.profile ? result.profile.role : "student";
    if(role !== "counsellor" && role !== "admin"){
      document.getElementById("fp-admin-gate").innerHTML =
        '<div class="fp-card"><p>This page is for counsellors and admins only.</p>' +
        '<a href="pathways.html" class="btn-secondary" style="display:inline-block; text-decoration:none;">Go to the student form</a></div>';
      document.getElementById("fp-admin-list-view").hidden = true;
      return;
    }

    return institutesPromise.then(function(r){
      (r.data||[]).forEach(function(x){ lookups.institutes[x.id] = x.name; });
      return Promise.all([facultiesPromise, careersPromise, firstPrioPromise, submissionsPromise]);
    }).then(function(rest){
      (rest[0].data||[]).forEach(function(x){ lookups.faculties[x.id] = x.name; });
      (rest[1].data||[]).forEach(function(x){ lookups.careers[x.id] = x.name; });
      applyFirstPriorities(rest[2]);
      applySubmissions(rest[3]);
    });
  }).catch(function(e){ console.error(e); });

  document.getElementById("fp-logout").addEventListener("click", function(){
    FP.signOut();
  });

  // "First priority" = preference_group 1, rank 1 -- the one unambiguous
  // single "top choice" given the schema has multiple preference groups
  // per student (2 for medical, 4 for engineering).
  function applyFirstPriorities(r){
    if(r.error){ console.error(r.error); return; }
    (r.data||[]).forEach(function(row){
      var name = row.custom_institute_name || lookups.institutes[row.institute_id] || null;
      if(name) firstPriorityByFpId[row.future_pathway_id] = name;
    });

    // Dropdown shows ONLY institutes that are actually someone's
    // first priority right now -- not the full master list. An
    // institute nobody has picked yet (e.g. seeded but unused)
    // stays out of the dropdown until a real submission names it.
    var usedNames = Array.from(new Set(Object.values(firstPriorityByFpId))).sort();
    var select = document.getElementById("filter-first-priority");
    select.innerHTML = '<option value="">All</option>' +
      usedNames.map(function(n){ return '<option value="' + esc(n) + '">' + esc(n) + '</option>'; }).join("");
    renderTable(); // in case submissions already rendered before this resolved
  }

  function applySubmissions(r){
    if(r.error){ console.error(r.error); return; }
    submissions = r.data || [];
    renderStatsStrip();
    renderTable();
  }

  function renderStatsStrip(){
    var el = document.getElementById("fp-stats-strip");
    if(!el) return;
    var submitted = submissions.filter(function(s){ return s.status === "submitted"; }).length;
    var draft = submissions.filter(function(s){ return s.status === "draft"; }).length;
    var engineering = submissions.filter(function(s){ return s.pathway === "engineering"; }).length;
    var medical = submissions.filter(function(s){ return s.pathway === "medical"; }).length;
    var stats = [
      ["TOTAL", submissions.length, ""],
      ["SUBMITTED", submitted, "accent-green"],
      ["DRAFT", draft, "accent-amber"],
      ["ENGINEERING", engineering, "accent-violet"],
      ["MEDICAL", medical, "accent-violet"]
    ];
    el.innerHTML = stats.map(function(s){
      return '<div class="fp-stat ' + s[2] + '"><div class="fp-stat-value">' + s[1] + '</div><div class="fp-stat-label">' + s[0] + '</div></div>';
    }).join("");
  }

  function renderTable(){
    var pathwayFilter = document.getElementById("filter-pathway").value;
    var statusFilter = document.getElementById("filter-status").value;
    var firstPriorityFilter = document.getElementById("filter-first-priority").value;
    var rows = submissions.filter(function(s){
      return (!pathwayFilter || s.pathway === pathwayFilter)
        && (!statusFilter || s.status === statusFilter)
        && (!firstPriorityFilter || firstPriorityByFpId[s.id] === firstPriorityFilter);
    });
    document.getElementById("fp-admin-tbody").innerHTML = rows.map(function(s){
      var name = titleCase((s.students && s.students.student_name) || "") || "(no profile yet)";
      var firstPriority = firstPriorityByFpId[s.id] || "\u2014";
      return '<tr data-id="' + s.id + '">' +
        '<td>' + esc(name) + '</td>' +
        '<td class="fp-cap">' + esc(s.pathway) + '</td>' +
        '<td>' + esc(firstPriority) + '</td>' +
        '<td><span class="fp-badge ' + s.status + '">' + s.status + '</span></td>' +
        '<td>' + (s.submitted_at ? new Date(s.submitted_at).toLocaleDateString() : "\u2014") + '</td>' +
      '</tr>';
    }).join("") || '<tr><td colspan="5">No submissions match these filters.</td></tr>';

    document.querySelectorAll("#fp-admin-tbody tr[data-id]").forEach(function(tr){
      tr.addEventListener("click", function(){ openDetail(tr.dataset.id); });
    });
  }

  document.getElementById("filter-pathway").addEventListener("change", renderTable);
  document.getElementById("filter-status").addEventListener("change", renderTable);
  document.getElementById("filter-first-priority").addEventListener("change", renderTable);

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }

  // Source data (real school records) has names in ALL CAPS; display
  // formatting shouldn't mutate the underlying stored value, just how
  // it's shown here. Straightforward per-word capitalization -- not
  // attempting name-particle exceptions (bin/binte/ul- etc), which
  // would need per-name judgment calls this shouldn't be guessing at.
  function titleCase(s){
    return String(s || "").toLowerCase().replace(/\b\w/g, function(c){ return c.toUpperCase(); });
  }

  // ---------------------------------------------------------
  // Detail view
  // ---------------------------------------------------------
  function openDetail(id){
    var sub = submissions.find(function(s){ return s.id === id; });
    if(!sub) return;

    document.getElementById("fp-admin-list-view").hidden = true;
    var detail = document.getElementById("fp-admin-detail-view");
    detail.hidden = false;
    detail.innerHTML = '<div class="fp-card"><p>Loading\u2026</p></div>';

    Promise.all([
      FP.client.from("student_institute_preferences").select("*").eq("future_pathway_id", id),
      FP.client.from("student_faculty_preferences").select("*").eq("future_pathway_id", id),
      FP.client.from("student_program_preferences").select("*").eq("future_pathway_id", id),
      FP.client.from("office_evaluations").select("*").eq("future_pathway_id", id).maybeSingle()
    ]).then(function(r){
      renderDetail(sub, r[0].data||[], r[1].data||[], r[2].data||[], r[3].data);
    });
  }

  function groupedRows(rows, nameLookup){
    var byGroup = {};
    rows.forEach(function(r){
      byGroup[r.preference_group] = byGroup[r.preference_group] || [];
      byGroup[r.preference_group][r.rank-1] = r.custom_institute_name || r.custom_faculty_name ||
        nameLookup[r.institute_id || r.faculty_id] || "\u2014";
    });
    return Object.keys(byGroup).sort().map(function(g){
      return '<div class="fp-review-row"><span>Group ' + g + '</span><span>' + byGroup[g].filter(Boolean).map(function(n,i){ return (i+1)+". "+esc(n); }).join(", ") + '</span></div>';
    }).join("");
  }

  function renderDetail(sub, instRows, facRows, progRows, evalRow){
    var p = sub.students || {};
    var careerNames = progRows.map(function(r){ return r.custom_program_name || lookups.careers[r.program_id] || lookups.faculties[r.program_id] || null; }).filter(Boolean);
    evalRow = evalRow || {};

    var profileHtml = ["student_name","father_name","father_profession","contact","discipline","section","roll_number","matric_marks","first_year_marks"]
      .map(function(k){ return '<div class="fp-review-row"><span>' + k.replace(/_/g," ") + '</span><span>' + esc(p[k]) + '</span></div>'; }).join("");

    var recFields = "";
    for(var i=1;i<=12;i++){
      recFields += '<label>Recommendation ' + i + '<input type="text" data-rec="' + i + '" value="' + esc(evalRow["recommendation_"+i] || "") + '"></label>';
    }

    document.getElementById("fp-admin-detail-view").innerHTML =
      '<button type="button" class="btn-secondary" id="fp-back-to-list" style="margin-bottom:16px;">&larr; Back to list</button>' +
      '<div class="fp-card">' +
        '<h2 class="fp-step-title">' + esc(p.student_name || "Student") + '</h2>' +
        '<p class="fp-step-desc">' + esc(sub.pathway) + ' \u2014 <span class="fp-badge ' + sub.status + '">' + sub.status + '</span></p>' +
        '<div class="fp-review-section"><h4>Student information</h4>' + profileHtml + '</div>' +
        '<div class="fp-review-section"><h4>Programs &amp; careers</h4><div class="fp-review-row"><span>Selected</span><span>' + esc(careerNames.join(", ") || "\u2014") + '</span></div></div>' +
        '<div class="fp-review-section"><h4>Institute preferences</h4>' + groupedRows(instRows, lookups.institutes) + '</div>' +
        '<div class="fp-review-section"><h4>Faculty preferences</h4>' + groupedRows(facRows, lookups.faculties) + '</div>' +
        '<div class="fp-review-section"><h4>Additional information</h4><p>' + esc(sub.additional_information || "\u2014") + '</p></div>' +
      '</div>' +
      '<div class="fp-card">' +
        '<h2 class="fp-step-title">Office evaluation</h2>' +
        '<div class="fp-form">' +
          '<div class="fp-grid-2">' + recFields + '</div>' +
          '<div class="fp-grid-2">' +
            '<label>Counsellor name<input type="text" id="eval-counsellor-name" value="' + esc(evalRow.counsellor_name||"") + '"></label>' +
            '<label>Counsellor signature<input type="text" id="eval-counsellor-signature" value="' + esc(evalRow.counsellor_signature||"") + '"></label>' +
          '</div>' +
          '<label>Principal<input type="text" id="eval-principal" value="' + esc(evalRow.principal||"") + '"></label>' +
          '<label>Remarks<textarea id="eval-remarks" rows="4" style="width:100%; font-family:var(--font-body); padding:10px 12px; border:1px solid var(--line-strong); border-radius:var(--radius-sm);">' + esc(evalRow.remarks||"") + '</textarea></label>' +
          '<button type="button" class="btn-primary" id="eval-save">Save evaluation</button>' +
          '<p class="fp-note" id="eval-saved" hidden>Saved.</p>' +
        '</div>' +
      '</div>';

    document.getElementById("fp-back-to-list").addEventListener("click", function(){
      document.getElementById("fp-admin-detail-view").hidden = true;
      document.getElementById("fp-admin-list-view").hidden = false;
    });

    document.getElementById("eval-save").addEventListener("click", function(){
      var record = { future_pathway_id: sub.id };
      for(var i=1;i<=12;i++){ record["recommendation_"+i] = document.querySelector('[data-rec="'+i+'"]').value; }
      record.counsellor_name = document.getElementById("eval-counsellor-name").value;
      record.counsellor_signature = document.getElementById("eval-counsellor-signature").value;
      record.principal = document.getElementById("eval-principal").value;
      record.remarks = document.getElementById("eval-remarks").value;

      FP.client.from("office_evaluations").upsert([record]).then(function(r){
        if(r.error){ alert("Could not save: " + r.error.message); return; }
        var el = document.getElementById("eval-saved");
        el.hidden = false;
        setTimeout(function(){ el.hidden = true; }, 2000);
      });
    });
  }
})();
