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

  // "+ Add new student" -- also available directly from admin.html
  // now, alongside the one already on pathways.html itself. Same
  // RPC + redirect either place: create the account, then land on
  // pathways.html?student=<id> to actually fill in the student's
  // info -- data entry always happens on the form page regardless
  // of where you started, this just saves a trip through the list
  // view first if you're already looking at it.
  var addStudentBtn = document.getElementById("fp-admin-add-student");
  if(addStudentBtn){
    addStudentBtn.addEventListener("click", function(){
      addStudentBtn.disabled = true;
      addStudentBtn.textContent = "Creating\u2026";
      FP.client.rpc("counsellor_create_student").then(function(r){
        if(r.error){
          alert("Could not create student: " + r.error.message);
          addStudentBtn.disabled = false;
          addStudentBtn.textContent = "+ Add new student";
          return;
        }
        window.location.href = "pathways.html?student=" + encodeURIComponent(r.data);
      });
    });
  }

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

  var selectedIds = new Set();

  function updateBulkActionsBar(){
    var bar = document.getElementById("fp-bulk-actions");
    var countEl = document.getElementById("fp-bulk-count");
    if(selectedIds.size === 0){
      bar.hidden = true;
      bar.classList.remove("reveal-in");
      return;
    }
    var wasHidden = bar.hidden;
    bar.hidden = false;
    countEl.textContent = selectedIds.size + " selected";
    if(wasHidden){
      // Draws the eye the moment it appears -- it's directly above
      // the table now (moved there specifically because it used to
      // sit above the filter row, several elements away from where
      // someone's actually looking when they check a box), but the
      // animation is extra insurance against it going unnoticed.
      bar.classList.remove("reveal-in");
      void bar.offsetWidth;
      bar.classList.add("reveal-in");
    }
  }

  function renderTable(){
    var nameFilter = document.getElementById("filter-name").value.trim().toLowerCase();
    var pathwayFilter = document.getElementById("filter-pathway").value;
    var statusFilter = document.getElementById("filter-status").value;
    var firstPriorityFilter = document.getElementById("filter-first-priority").value;
    var rows = submissions.filter(function(s){
      var studentName = ((s.students && s.students.student_name) || "").toLowerCase();
      return (!nameFilter || studentName.indexOf(nameFilter) !== -1)
        && (!pathwayFilter || s.pathway === pathwayFilter)
        && (!statusFilter || s.status === statusFilter)
        && (!firstPriorityFilter || firstPriorityByFpId[s.id] === firstPriorityFilter);
    });
    document.getElementById("fp-admin-tbody").innerHTML = rows.map(function(s){
      var name = titleCase((s.students && s.students.student_name) || "") || "(no profile yet)";
      var firstPriority = firstPriorityByFpId[s.id] || "\u2014";
      var checked = selectedIds.has(s.id) ? " checked" : "";
      return '<tr data-id="' + s.id + '">' +
        '<td><input type="checkbox" class="fp-row-select" data-id="' + s.id + '" aria-label="Select ' + esc(name) + '"' + checked + '></td>' +
        '<td>' + esc(name) + '</td>' +
        '<td class="fp-cap">' + esc(s.pathway) + '</td>' +
        '<td>' + esc(firstPriority) + '</td>' +
        '<td><span class="fp-badge ' + s.status + '">' + s.status + '</span></td>' +
        '<td>' + (s.submitted_at ? new Date(s.submitted_at).toLocaleDateString() : "\u2014") + '</td>' +
        '<td class="fp-row-actions">' +
          '<a href="pathways.html?student=' + esc(s.student_id) + '" class="fp-row-action-link">Edit</a>' +
          '<button type="button" class="fp-row-action-link fp-row-action-delete" data-reset-id="' + s.id + '">Delete</button>' +
        '</td>' +
      '</tr>';
    }).join("") || '<tr><td colspan="7">No submissions match these filters.</td></tr>';

    document.querySelectorAll("#fp-admin-tbody tr[data-id]").forEach(function(tr){
      tr.addEventListener("click", function(e){
        if(e.target.closest(".fp-row-actions") || e.target.closest(".fp-row-select")) return; // let row actions/checkbox handle their own clicks
        openDetail(tr.dataset.id);
      });
    });

    document.querySelectorAll("#fp-admin-tbody .fp-row-select").forEach(function(cb){
      cb.addEventListener("click", function(e){ e.stopPropagation(); });
      cb.addEventListener("change", function(){
        if(cb.checked) selectedIds.add(cb.dataset.id);
        else selectedIds.delete(cb.dataset.id);
        var selectAll = document.getElementById("fp-select-all");
        var visibleBoxes = document.querySelectorAll("#fp-admin-tbody .fp-row-select");
        selectAll.checked = visibleBoxes.length > 0 && Array.from(visibleBoxes).every(function(b){ return b.checked; });
        updateBulkActionsBar();
      });
    });

    document.querySelectorAll("#fp-admin-tbody .fp-row-action-delete").forEach(function(btn){
      btn.addEventListener("click", function(e){
        e.stopPropagation();
        var fpId = btn.dataset.resetId;
        var sub = submissions.find(function(x){ return x.id === fpId; });
        if(!sub) return;
        var studentName = titleCase((sub.students && sub.students.student_name) || "");
        resetSubmission(fpId, studentName, btn, function(ok){
          if(!ok) return;
          sub.status = "draft";
          sub.submitted_at = null;
          sub.additional_information = null;
          selectedIds.delete(fpId);
          renderTable();
          updateBulkActionsBar();
        });
      });
    });

    var selectAllBox = document.getElementById("fp-select-all");
    var visibleBoxesNow = document.querySelectorAll("#fp-admin-tbody .fp-row-select");
    selectAllBox.checked = visibleBoxesNow.length > 0 && Array.from(visibleBoxesNow).every(function(b){ return b.checked; });
  }

  document.getElementById("fp-select-all").addEventListener("change", function(e){
    var checked = e.target.checked;
    document.querySelectorAll("#fp-admin-tbody .fp-row-select").forEach(function(cb){
      cb.checked = checked;
      if(checked) selectedIds.add(cb.dataset.id);
      else selectedIds.delete(cb.dataset.id);
    });
    updateBulkActionsBar();
  });

  document.getElementById("fp-bulk-delete").addEventListener("click", function(){
    var ids = Array.from(selectedIds);
    if(!ids.length) return;

    var names = ids.map(function(id){
      var sub = submissions.find(function(x){ return x.id === id; });
      return sub ? (titleCase((sub.students && sub.students.student_name) || "") || null) : null;
    }).filter(Boolean);

    var confirmMsg = "Reset " + ids.length + " student" + (ids.length === 1 ? "" : "s") + "'s form" + (ids.length === 1 ? "" : "s") + " back to editable drafts?\n\n" +
      (names.length ? names.slice(0, 6).join(", ") + (names.length > 6 ? ", and " + (names.length - 6) + " more" : "") + "\n\n" : "") +
      "This clears their submitted answers but keeps their accounts and profile info intact.";

    FP.confirm(confirmMsg).then(function(confirmed){
      if(!confirmed) return;
      var bulkBtn = document.getElementById("fp-bulk-delete");
      bulkBtn.disabled = true;
      Promise.all(ids.map(function(id){
        return new Promise(function(resolve){
          performReset(id, null, function(ok){
            if(ok){
              var sub = submissions.find(function(x){ return x.id === id; });
              if(sub){ sub.status = "draft"; sub.submitted_at = null; sub.additional_information = null; }
              selectedIds.delete(id);
            }
            resolve();
          });
        });
      })).then(function(){
        bulkBtn.disabled = false;
        renderTable();
        updateBulkActionsBar();
      });
    });
  });

  document.getElementById("filter-name").addEventListener("input", renderTable);
  document.getElementById("filter-pathway").addEventListener("change", renderTable);
  document.getElementById("filter-status").addEventListener("change", renderTable);
  document.getElementById("filter-first-priority").addEventListener("change", renderTable);

  // Shared "delete" action -- per the confirmed meaning from when
  // this was first built: reset to an editable draft, keep the
  // account (student_name/roll number/marks untouched), clear the
  // answers (preferences + additional_information). Used by both
  // the detail view's own button and the table row quick action
  // below, so the confirm-copy/RPC-call/error-handling only exists
  // once. Disables the triggering button for the duration of the
  // call so a double-click can't fire two resets.
  // Does the actual RPC call, no confirmation -- callers decide when/
  // how to confirm (a single row asks about one student, a bulk
  // action asks once about the whole batch, not once per student).
  function performReset(fpId, triggerBtn, onDone){
    if(triggerBtn) triggerBtn.disabled = true;
    FP.client.rpc("counsellor_reset_submission", { p_future_pathway_id: fpId }).then(function(r){
      if(r.error){
        alert("Could not reset: " + r.error.message);
        if(triggerBtn) triggerBtn.disabled = false;
        onDone(false);
        return;
      }
      onDone(true);
    });
  }

  function resetSubmission(fpId, studentName, triggerBtn, onDone){
    var confirmMsg = "Reset " + (studentName || "this student") + "'s form back to an editable draft?\n\n" +
      "This clears their submitted answers (institute/faculty/program preferences and additional information) " +
      "but keeps their account and profile info (name, roll number, marks) intact.";

    FP.confirm(confirmMsg).then(function(confirmed){
      if(!confirmed){ onDone(false); return; }
      performReset(fpId, triggerBtn, onDone);
    });
  }

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

  // Four independently-collapsible sections (institute pathway has 4
  // groups, medical has 2) -- each shows that group's 5 ranked
  // preferences when expanded. Not tabs: more than one group can be
  // open at once, since a counsellor comparing groups 1 and 3 side
  // by side shouldn't have to close one to see the other.
  function groupedAccordion(rows, nameLookup, idPrefix){
    var byGroup = {};
    rows.forEach(function(r){
      byGroup[r.preference_group] = byGroup[r.preference_group] || [];
      byGroup[r.preference_group][r.rank-1] = r.custom_institute_name || r.custom_faculty_name ||
        nameLookup[r.institute_id || r.faculty_id] || null;
    });

    var groupNums = Object.keys(byGroup).sort();
    if(!groupNums.length){
      return '<p class="fp-accordion-empty">No preferences submitted yet.</p>';
    }

    return '<div class="fp-accordion">' + groupNums.map(function(g){
      var picks = byGroup[g];
      var panelId = idPrefix + "-group-" + g;
      var listItems = picks.map(function(name, i){
        return name ? '<li value="' + (i+1) + '">' + esc(name) + '</li>' : "";
      }).filter(Boolean).join("");
      var body = listItems ? '<ol class="fp-accordion-list">' + listItems + '</ol>' : '<p class="fp-accordion-empty">No picks in this group yet.</p>';

      return (
        '<div class="fp-accordion-item">' +
          '<button type="button" class="fp-accordion-header" aria-expanded="false" data-accordion-target="' + panelId + '">' +
            '<span>Group ' + esc(g) + '</span>' +
            '<span class="fp-accordion-chevron">&#9662;</span>' +
          '</button>' +
          '<div class="fp-accordion-panel-wrapper" id="' + panelId + '">' +
            '<div class="fp-accordion-panel">' + body + '</div>' +
          '</div>' +
        '</div>'
      );
    }).join("") + '</div>';
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
        '<div style="display:flex; align-items:baseline; justify-content:space-between; flex-wrap:wrap; gap:10px;">' +
          '<h2 class="fp-step-title" style="margin-bottom:0;">' + esc(p.student_name || "Student") + '</h2>' +
          '<div style="display:flex; gap:8px;">' +
            '<a href="pathways.html?student=' + esc(sub.student_id) + '" class="nav-link">Edit this form</a>' +
            '<button type="button" class="nav-link" id="fp-reset-submission" style="color:var(--red);">Reset to draft</button>' +
          '</div>' +
        '</div>' +
        '<p class="fp-step-desc">' + esc(sub.pathway) + ' \u2014 <span class="fp-badge ' + sub.status + '">' + sub.status + '</span></p>' +
        '<div class="fp-review-section"><h4>Student information</h4>' + profileHtml + '</div>' +
        '<div class="fp-review-section"><h4>Programs &amp; careers</h4><div class="fp-review-row"><span>Selected</span><span>' + esc(careerNames.join(", ") || "\u2014") + '</span></div></div>' +
        '<div class="fp-review-section"><h4>Institute preferences</h4>' + groupedAccordion(instRows, lookups.institutes, "inst") + '</div>' +
        '<div class="fp-review-section"><h4>Faculty preferences</h4>' + groupedAccordion(facRows, lookups.faculties, "fac") + '</div>' +
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

    document.querySelectorAll(".fp-accordion-header").forEach(function(btn){
      btn.addEventListener("click", function(){
        var panel = document.getElementById(btn.dataset.accordionTarget);
        var isOpen = btn.getAttribute("aria-expanded") === "true";
        btn.setAttribute("aria-expanded", isOpen ? "false" : "true");
        panel.classList.toggle("is-open", !isOpen);
      });
    });

    var resetBtn = document.getElementById("fp-reset-submission");
    if(resetBtn){
      resetBtn.addEventListener("click", function(){
        resetSubmission(sub.id, p.student_name, resetBtn, function(ok){
          if(!ok) return;
          sub.status = "draft";
          sub.submitted_at = null;
          sub.additional_information = null;
          openDetail(sub.id); // re-fetch and re-render with the cleared preferences
        });
      });
    }

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
