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
          FP.toast.error("Could not create student: " + r.error.message);
          addStudentBtn.disabled = false;
          addStudentBtn.textContent = "+ Add new student";
          return;
        }
        FP.toast.success("Student account created");
        window.location.href = "pathways.html?student=" + encodeURIComponent(r.data);
      });
    });
  }

  // Export CSV
  var exportCsvBtn = document.getElementById("fp-export-csv");
  if(exportCsvBtn){
    exportCsvBtn.addEventListener("click", function(){
      exportSubmissionsToCSV();
    });
  }

  function exportSubmissionsToCSV(){
    var filtered = getFilteredSubmissions();
    if(!filtered.length){
      FP.toast.info("No submissions match the current filters to export.");
      return;
    }
    var headers = ["Student Name", "Father Name", "Contact", "Roll Number", "Matric Marks", "First Year Marks", "Pathway", "First Priority", "Status", "Submitted At"];
    var rows = filtered.map(function(s){
      var p = s.students || {};
      return [
        titleCase(p.student_name || ""),
        titleCase(p.father_name || ""),
        p.contact || "",
        p.roll_number || "",
        p.matric_marks || "",
        p.first_year_marks || "",
        s.pathway || "",
        firstPriorityByFpId[s.id] || "",
        s.status || "",
        s.submitted_at ? new Date(s.submitted_at).toLocaleString() : ""
      ].map(function(val){
        var str = String(val).replace(/"/g, '""');
        return '"' + str + '"';
      }).join(",");
    });
    var csvContent = headers.join(",") + "\r\n" + rows.join("\r\n");
    var blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a");
    a.href = url;
    a.download = "future_pathways_students_" + new Date().toISOString().slice(0,10) + ".csv";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    FP.toast.success("Exported " + filtered.length + " students to CSV");
  }

  // "First priority" = preference_group 1, rank 1
  function applyFirstPriorities(r){
    if(r.error){ console.error(r.error); return; }
    (r.data||[]).forEach(function(row){
      var name = row.custom_institute_name || lookups.institutes[row.institute_id] || null;
      if(name) firstPriorityByFpId[row.future_pathway_id] = name;
    });

    var usedNames = Array.from(new Set(Object.values(firstPriorityByFpId))).sort();
    var select = document.getElementById("filter-first-priority");
    select.innerHTML = '<option value="">All</option>' +
      usedNames.map(function(n){ return '<option value="' + esc(n) + '">' + esc(n) + '</option>'; }).join("");
    renderTable();
  }

  function applySubmissions(r){
    if(r.error){ console.error(r.error); return; }
    submissions = r.data || [];
    renderStatsStrip();
    renderTable();
  }

  // ---------------------------------------------------------
  // Missing event listeners — these functions were defined in
  // the overhaul commit but never wired to the DOM elements.
  // ---------------------------------------------------------

  // Select-all checkbox
  document.getElementById("fp-select-all").addEventListener("change", function(e){
    var checked = e.target.checked;
    document.querySelectorAll("#fp-admin-tbody .fp-row-select").forEach(function(cb){
      cb.checked = checked;
      if(checked) selectedIds.add(cb.dataset.id);
      else selectedIds.delete(cb.dataset.id);
    });
    updateBulkActionsBar();
  });

  // Bulk action dropdown toggle
  document.getElementById("fp-bulk-dropdown-toggle").addEventListener("click", function(e){
    toggleBulkMenu(e);
  });
  document.addEventListener("click", function(e){
    if(!e.target.closest(".fp-bulk-menu-wrapper")) closeBulkMenu();
  });

  // Bulk "Clear data for selected" (dropdown item)
  document.getElementById("fp-bulk-clear").addEventListener("click", function(){
    closeBulkMenu();
    var ids = Array.from(selectedIds);
    if(!ids.length) return;
    var names = ids.map(function(id){
      var sub = submissions.find(function(x){ return x.id === id; });
      return sub ? (titleCase((sub.students && sub.students.student_name) || "") || null) : null;
    }).filter(Boolean);
    var confirmMsg = "Clear data for " + ids.length + " student" + (ids.length === 1 ? "" : "s") + "?\n\n" +
      (names.length ? names.slice(0, 6).join(", ") + (names.length > 6 ? ", and " + (names.length - 6) + " more" : "") + "\n\n" : "") +
      "This resets their forms to draft and clears submitted answers, but keeps their accounts and profile info (name, marks) intact.";
    FP.confirm(confirmMsg).then(function(confirmed){
      if(!confirmed) return;
      setBulkLoading(true, "Clearing\u2026");
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
        setBulkLoading(false);
        FP.toast.success("Cleared data for " + ids.length + " student" + (ids.length === 1 ? "" : "s"));
        renderStatsStrip();
        renderTable();
        updateBulkActionsBar();
      });
    });
  });

  // Bulk "Delete selected" (dropdown item)
  document.getElementById("fp-bulk-delete").addEventListener("click", function(){
    closeBulkMenu();
    var ids = Array.from(selectedIds);
    if(!ids.length) return;
    var studentIds = ids.map(function(id){
      var sub = submissions.find(function(x){ return x.id === id; });
      return sub ? { fpId: id, studentId: sub.student_id, name: titleCase((sub.students && sub.students.student_name) || "") } : null;
    }).filter(Boolean);
    var names = studentIds.map(function(s){ return s.name; }).filter(Boolean);
    var confirmMsg = "Permanently delete " + studentIds.length + " student account" + (studentIds.length === 1 ? "" : "s") + "?\n\n" +
      (names.length ? names.slice(0, 6).join(", ") + (names.length > 6 ? ", and " + (names.length - 6) + " more" : "") + "\n\n" : "") +
      "This removes their names, profiles, and all submitted data from the database completely. This cannot be undone.";
    FP.confirm(confirmMsg).then(function(confirmed){
      if(!confirmed) return;
      setBulkLoading(true, "Deleting\u2026");
      Promise.all(studentIds.map(function(s){
        return new Promise(function(resolve){
          FP.client.rpc("counsellor_delete_student", { p_student_id: s.studentId }).then(function(r){
            if(!r.error){
              submissions = submissions.filter(function(x){ return x.id !== s.fpId; });
              selectedIds.delete(s.fpId);
            }
            resolve();
          });
        });
      })).then(function(){
        setBulkLoading(false);
        FP.toast.success("Deleted " + studentIds.length + " student account" + (studentIds.length === 1 ? "" : "s"));
        renderStatsStrip();
        renderTable();
        updateBulkActionsBar();
      });
    });
  });

  // Quick-action buttons removed (dropdown covers both actions now)

  // Column sort headers
  document.querySelectorAll(".fp-th-sortable").forEach(function(th){
    th.querySelector(".fp-th-btn").addEventListener("click", function(){
      var col = th.dataset.sort;
      if(sortState.col === col){
        sortState.dir = sortState.dir === "asc" ? "desc" : "asc";
      } else {
        sortState.col = col;
        sortState.dir = "asc";
      }
      paginationState.page = 1;
      renderTable();
    });
  });

  // Filter inputs
  document.getElementById("filter-name").addEventListener("input", function(){ paginationState.page = 1; renderTable(); });
  document.getElementById("filter-pathway").addEventListener("change", function(){ paginationState.page = 1; renderTable(); });
  document.getElementById("filter-status").addEventListener("change", function(){ paginationState.page = 1; renderTable(); });
  document.getElementById("filter-first-priority").addEventListener("change", function(){ paginationState.page = 1; renderTable(); });

  // ---------------------------------------------------------
  // Action functions (missing from overhaul commit)
  // ---------------------------------------------------------

  function performReset(fpId, triggerBtn, onDone){
    if(triggerBtn) triggerBtn.disabled = true;
    FP.client.rpc("counsellor_reset_submission", { p_future_pathway_id: fpId }).then(function(r){
      if(r.error){
        FP.toast.error("Could not reset: " + r.error.message);
        if(triggerBtn) triggerBtn.disabled = false;
        onDone(false);
        return;
      }
      onDone(true);
    });
  }

  function resetSubmission(fpId, studentName, triggerBtn, onDone){
    var confirmMsg = "Clear " + (studentName || "this student") + "'s form back to an editable draft?\n\n" +
      "This clears their submitted answers but keeps their account and profile info (name, roll number, marks) intact.";
    FP.confirm(confirmMsg).then(function(confirmed){
      if(!confirmed){ onDone(false); return; }
      performReset(fpId, triggerBtn, onDone);
    });
  }

  function deleteStudent(studentId, studentName, triggerBtn, onDone){
    var confirmMsg = "Permanently delete " + (studentName || "this student") + "'s account?\n\n" +
      "This removes their name, profile, and every submitted answer from the database completely \u2014 " +
      "not just this form. This cannot be undone. If you only want to clear their submitted answers " +
      "and let them start over, use \u201cClear data\u201d instead.";
    FP.confirm(confirmMsg).then(function(confirmed){
      if(!confirmed){ onDone(false); return; }
      if(triggerBtn) triggerBtn.disabled = true;
      FP.client.rpc("counsellor_delete_student", { p_student_id: studentId }).then(function(r){
        if(r.error){
          FP.toast.error("Could not delete: " + r.error.message);
          if(triggerBtn) triggerBtn.disabled = false;
          onDone(false);
          return;
        }
        onDone(true);
      });
    });
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
  var sortState = { col: null, dir: "asc" };
  var paginationState = { page: 1, pageSize: 25 };

  function closeBulkMenu(){
    var menu = document.getElementById("fp-bulk-dropdown-menu");
    var toggle = document.getElementById("fp-bulk-dropdown-toggle");
    if(menu) menu.hidden = true;
    if(toggle) toggle.setAttribute("aria-expanded", "false");
  }

  function toggleBulkMenu(e){
    if(e) e.stopPropagation();
    var menu = document.getElementById("fp-bulk-dropdown-menu");
    var toggle = document.getElementById("fp-bulk-dropdown-toggle");
    if(!menu) return;
    var isHidden = menu.hidden;
    menu.hidden = !isHidden;
    if(toggle) toggle.setAttribute("aria-expanded", String(isHidden));
  }

  function setBulkLoading(isLoading, label){
    var btns = document.querySelectorAll(".fp-bulk-actions button");
    btns.forEach(function(b){ b.disabled = isLoading; });
    var countEl = document.getElementById("fp-bulk-count");
    if(countEl && label){
      countEl.textContent = label;
    }
  }

  function updateBulkActionsBar(){
    var bar = document.getElementById("fp-bulk-actions");
    var countEl = document.getElementById("fp-bulk-count");
    if(selectedIds.size === 0){
      bar.hidden = true;
      bar.classList.remove("reveal-in");
      closeBulkMenu();
      return;
    }
    var wasHidden = bar.hidden;
    bar.hidden = false;
    countEl.textContent = selectedIds.size + (selectedIds.size === 1 ? " student" : " students") + " selected";
    if(wasHidden){
      bar.classList.remove("reveal-in");
      void bar.offsetWidth;
      bar.classList.add("reveal-in");
    }
  }

  function getFilteredSubmissions(){
    var nameFilter = (document.getElementById("filter-name").value || "").trim().toLowerCase();
    var pathwayFilter = document.getElementById("filter-pathway").value;
    var statusFilter = document.getElementById("filter-status").value;
    var firstPriorityFilter = document.getElementById("filter-first-priority").value;
    return submissions.filter(function(s){
      var studentName = ((s.students && s.students.student_name) || "").toLowerCase();
      return (!nameFilter || studentName.indexOf(nameFilter) !== -1)
        && (!pathwayFilter || s.pathway === pathwayFilter)
        && (!statusFilter || s.status === statusFilter)
        && (!firstPriorityFilter || firstPriorityByFpId[s.id] === firstPriorityFilter);
    });
  }

  function sortRows(rows){
    if(!sortState.col) return rows;
    return rows.slice().sort(function(a, b){
      var valA, valB;
      if(sortState.col === "name"){
        valA = ((a.students && a.students.student_name) || "").toLowerCase();
        valB = ((b.students && b.students.student_name) || "").toLowerCase();
      } else if(sortState.col === "pathway"){
        valA = (a.pathway || "").toLowerCase();
        valB = (b.pathway || "").toLowerCase();
      } else if(sortState.col === "first_priority"){
        valA = (firstPriorityByFpId[a.id] || "").toLowerCase();
        valB = (firstPriorityByFpId[b.id] || "").toLowerCase();
      } else if(sortState.col === "status"){
        valA = (a.status || "").toLowerCase();
        valB = (b.status || "").toLowerCase();
      } else if(sortState.col === "submitted_at"){
        valA = a.submitted_at ? new Date(a.submitted_at).getTime() : 0;
        valB = b.submitted_at ? new Date(b.submitted_at).getTime() : 0;
      } else {
        valA = a.created_at ? new Date(a.created_at).getTime() : 0;
        valB = b.created_at ? new Date(b.created_at).getTime() : 0;
      }
      if(valA < valB) return sortState.dir === "asc" ? -1 : 1;
      if(valA > valB) return sortState.dir === "asc" ? 1 : -1;
      return 0;
    });
  }

  function renderFilterChips(){
    var chipsContainer = document.getElementById("fp-active-filter-chips");
    if(!chipsContainer) return;
    var name = (document.getElementById("filter-name").value || "").trim();
    var pathway = document.getElementById("filter-pathway").value;
    var status = document.getElementById("filter-status").value;
    var firstPrio = document.getElementById("filter-first-priority").value;

    var chips = [];
    if(name) chips.push({ type: "name", label: 'Search: "' + name + '"' });
    if(pathway) chips.push({ type: "pathway", label: 'Pathway: ' + (pathway === "engineering" ? "Engineering" : "Medical") });
    if(status) chips.push({ type: "status", label: 'Status: ' + status });
    if(firstPrio) chips.push({ type: "first_priority", label: '1st Choice: ' + firstPrio });

    if(!chips.length){
      chipsContainer.hidden = true;
      chipsContainer.innerHTML = "";
      return;
    }

    chipsContainer.hidden = false;
    chipsContainer.innerHTML = chips.map(function(c){
      return '<span class="fp-chip"><span>' + esc(c.label) + '</span> <button type="button" class="fp-chip-remove" data-chip="' + c.type + '" aria-label="Remove filter">&times;</button></span>';
    }).join("") + '<button type="button" class="fp-chip-clear-all" id="fp-clear-all-chips">Clear filters</button>';

    chipsContainer.querySelectorAll(".fp-chip-remove").forEach(function(btn){
      btn.addEventListener("click", function(){
        var t = btn.dataset.chip;
        if(t === "name") document.getElementById("filter-name").value = "";
        if(t === "pathway") document.getElementById("filter-pathway").value = "";
        if(t === "status") document.getElementById("filter-status").value = "";
        if(t === "first_priority") document.getElementById("filter-first-priority").value = "";
        paginationState.page = 1;
        renderTable();
      });
    });

    var clearAll = document.getElementById("fp-clear-all-chips");
    if(clearAll){
      clearAll.addEventListener("click", function(){
        document.getElementById("filter-name").value = "";
        document.getElementById("filter-pathway").value = "";
        document.getElementById("filter-status").value = "";
        document.getElementById("filter-first-priority").value = "";
        paginationState.page = 1;
        renderTable();
      });
    }
  }

  function renderPagination(totalCount){
    var bar = document.getElementById("fp-pagination-bar");
    if(!bar) return;
    if(totalCount === 0){
      bar.hidden = true;
      return;
    }
    bar.hidden = false;

    var size = paginationState.pageSize === "all" ? totalCount : parseInt(paginationState.pageSize, 10);
    var totalPages = Math.ceil(totalCount / size) || 1;
    if(paginationState.page > totalPages) paginationState.page = totalPages;

    var startIdx = paginationState.pageSize === "all" ? 1 : ((paginationState.page - 1) * size + 1);
    var endIdx = paginationState.pageSize === "all" ? totalCount : Math.min(paginationState.page * size, totalCount);

    bar.innerHTML =
      '<div class="fp-pagination-info">Showing <strong>' + startIdx + '&ndash;' + endIdx + '</strong> of <strong>' + totalCount + '</strong> students</div>' +
      '<div class="fp-pagination-controls">' +
        '<label style="display:inline-flex; align-items:center; gap:6px; font-size:.74rem; font-family:var(--font-mono);">' +
          'Rows:' +
          '<select class="fp-page-size-select" id="fp-page-size-select">' +
            '<option value="25"' + (paginationState.pageSize == 25 ? ' selected' : '') + '>25</option>' +
            '<option value="50"' + (paginationState.pageSize == 50 ? ' selected' : '') + '>50</option>' +
            '<option value="100"' + (paginationState.pageSize == 100 ? ' selected' : '') + '>100</option>' +
            '<option value="all"' + (paginationState.pageSize === 'all' ? ' selected' : '') + '>All</option>' +
          '</select>' +
        '</label>' +
        '<button type="button" class="fp-page-btn" id="fp-page-prev"' + (paginationState.page <= 1 ? ' disabled' : '') + '>&larr; Prev</button>' +
        '<span style="font-family:var(--font-mono); font-size:.74rem; padding: 0 4px;">' + paginationState.page + ' / ' + totalPages + '</span>' +
        '<button type="button" class="fp-page-btn" id="fp-page-next"' + (paginationState.page >= totalPages ? ' disabled' : '') + '>Next &rarr;</button>' +
      '</div>';

    var pageSizeSelect = document.getElementById("fp-page-size-select");
    if(pageSizeSelect){
      pageSizeSelect.addEventListener("change", function(e){
        paginationState.pageSize = e.target.value;
        paginationState.page = 1;
        renderTable();
      });
    }
    var prevBtn = document.getElementById("fp-page-prev");
    if(prevBtn){
      prevBtn.addEventListener("click", function(){
        if(paginationState.page > 1){
          paginationState.page--;
          renderTable();
        }
      });
    }
    var nextBtn = document.getElementById("fp-page-next");
    if(nextBtn){
      nextBtn.addEventListener("click", function(){
        if(paginationState.page < totalPages){
          paginationState.page++;
          renderTable();
        }
      });
    }
  }

  function updateSortHeaders(){
    document.querySelectorAll(".fp-th-sortable").forEach(function(th){
      var col = th.dataset.sort;
      var icon = th.querySelector(".fp-th-sort-icon");
      if(sortState.col === col){
        th.classList.add("is-sorted");
        if(icon) icon.innerHTML = sortState.dir === "asc" ? "&#9650;" : "&#9660;";
      } else {
        th.classList.remove("is-sorted");
        if(icon) icon.innerHTML = "&#8693;";
      }
    });
  }

  function renderTable(){
    renderFilterChips();
    var filtered = getFilteredSubmissions();
    var sorted = sortRows(filtered);
    updateSortHeaders();

    var totalCount = sorted.length;
    var size = paginationState.pageSize === "all" ? totalCount : parseInt(paginationState.pageSize, 10);
    var start = paginationState.pageSize === "all" ? 0 : (paginationState.page - 1) * size;
    var pagedRows = sorted.slice(start, start + size);

    var tbody = document.getElementById("fp-admin-tbody");
    if(totalCount === 0){
      tbody.innerHTML =
        '<tr><td colspan="7">' +
          '<div class="fp-empty-state">' +
            '<div class="fp-empty-icon">&#128269;</div>' +
            '<h3>No students found</h3>' +
            '<p>No submissions match the current filters. Try changing your search query or reset filters.</p>' +
            '<button type="button" class="btn-secondary" id="fp-empty-reset-btn">Reset all filters</button>' +
          '</div>' +
        '</td></tr>';
      var emptyResetBtn = document.getElementById("fp-empty-reset-btn");
      if(emptyResetBtn){
        emptyResetBtn.addEventListener("click", function(){
          document.getElementById("filter-name").value = "";
          document.getElementById("filter-pathway").value = "";
          document.getElementById("filter-status").value = "";
          document.getElementById("filter-first-priority").value = "";
          paginationState.page = 1;
          renderTable();
        });
      }
      renderPagination(0);
      return;
    }

    tbody.innerHTML = pagedRows.map(function(s){
      var name = titleCase((s.students && s.students.student_name) || "") || "(no profile yet)";
      var firstPriority = firstPriorityByFpId[s.id] || "\u2014";
      var checked = selectedIds.has(s.id) ? " checked" : "";
      return '<tr data-id="' + s.id + '">' +
        '<td class="fp-select-td"><label class="fp-select-cell"><input type="checkbox" class="fp-row-select" data-id="' + s.id + '" aria-label="Select ' + esc(name) + '"' + checked + '></label></td>' +
        '<td><strong>' + esc(name) + '</strong></td>' +
        '<td class="fp-cap">' + esc(s.pathway) + '</td>' +
        '<td>' + esc(firstPriority) + '</td>' +
        '<td><span class="fp-badge ' + s.status + '">' + s.status + '</span></td>' +
        '<td>' + (s.submitted_at ? new Date(s.submitted_at).toLocaleDateString() : "\u2014") + '</td>' +
        '<td class="fp-row-actions">' +
          '<a href="pathways.html?student=' + esc(s.student_id) + '" class="fp-row-action-link">Edit</a>' +
          '<button type="button" class="fp-row-action-link fp-row-action-clear" data-clear-id="' + s.id + '">Clear data</button>' +
          '<button type="button" class="fp-row-action-link fp-row-action-delete" data-delete-id="' + s.id + '" data-student-id="' + esc(s.student_id) + '">Delete</button>' +
        '</td>' +
      '</tr>';
    }).join("");

    document.querySelectorAll("#fp-admin-tbody tr[data-id]").forEach(function(tr){
      tr.addEventListener("click", function(e){
        if(e.target.closest(".fp-row-actions") || e.target.closest(".fp-select-td")) return;
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

    // "Clear data" -- resets to an editable draft, keeps the account.
    document.querySelectorAll("#fp-admin-tbody .fp-row-action-clear").forEach(function(btn){
      btn.addEventListener("click", function(e){
        e.stopPropagation();
        var fpId = btn.dataset.clearId;
        var sub = submissions.find(function(x){ return x.id === fpId; });
        if(!sub) return;
        var studentName = titleCase((sub.students && sub.students.student_name) || "");
        resetSubmission(fpId, studentName, btn, function(ok){
          if(!ok) return;
          sub.status = "draft";
          sub.submitted_at = null;
          sub.additional_information = null;
          selectedIds.delete(fpId);
          FP.toast.success("Reset " + (studentName || "student") + "'s form to draft");
          renderStatsStrip();
          renderTable();
          updateBulkActionsBar();
        });
      });
    });

    // "Delete" -- REAL, PERMANENT deletion. Removes student account entirely.
    document.querySelectorAll("#fp-admin-tbody .fp-row-action-delete").forEach(function(btn){
      btn.addEventListener("click", function(e){
        e.stopPropagation();
        var fpId = btn.dataset.deleteId;
        var studentId = btn.dataset.studentId;
        var sub = submissions.find(function(x){ return x.id === fpId; });
        if(!sub) return;
        var studentName = titleCase((sub.students && sub.students.student_name) || "");
        deleteStudent(studentId, studentName, btn, function(ok){
          if(!ok) return;
          submissions = submissions.filter(function(x){ return x.id !== fpId; });
          selectedIds.delete(fpId);
          FP.toast.success("Deleted " + (studentName || "student") + "'s account");
          renderStatsStrip();
          renderTable();
          updateBulkActionsBar();
        });
      });
    });

    var selectAllBox = document.getElementById("fp-select-all");
    var visibleBoxesNow = document.querySelectorAll("#fp-admin-tbody .fp-row-select");
    selectAllBox.checked = visibleBoxesNow.length > 0 && Array.from(visibleBoxesNow).every(function(b){ return b.checked; });

    renderPagination(totalCount);
  }

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }

  // Source data (real school records) has names in ALL CAPS
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

  // Four independently-collapsible sections
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
            '<button type="button" class="nav-link" id="fp-reset-submission" style="color:var(--amber);">Clear student\'s data</button>' +
            '<button type="button" class="nav-link" id="fp-delete-student" style="color:var(--red);">Delete</button>' +
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
          FP.toast.success("Reset " + (p.student_name || "student") + "'s form to draft");
          renderStatsStrip();
          openDetail(sub.id);
        });
      });
    }

    var deleteBtn = document.getElementById("fp-delete-student");
    if(deleteBtn){
      deleteBtn.addEventListener("click", function(){
        deleteStudent(sub.student_id, p.student_name, deleteBtn, function(ok){
          if(!ok) return;
          submissions = submissions.filter(function(x){ return x.id !== sub.id; });
          document.getElementById("fp-admin-detail-view").hidden = true;
          document.getElementById("fp-admin-list-view").hidden = false;
          FP.toast.success("Deleted " + (p.student_name || "student") + "'s account");
          renderStatsStrip();
          renderTable();
          updateBulkActionsBar();
        });
      });
    }

    document.getElementById("eval-save").addEventListener("click", function(){
      var saveBtn = document.getElementById("eval-save");
      saveBtn.disabled = true;
      saveBtn.textContent = "Saving\u2026";
      var record = { future_pathway_id: sub.id };
      for(var i=1;i<=12;i++){ record["recommendation_"+i] = document.querySelector('[data-rec="'+i+'"]').value; }
      record.counsellor_name = document.getElementById("eval-counsellor-name").value;
      record.counsellor_signature = document.getElementById("eval-counsellor-signature").value;
      record.principal = document.getElementById("eval-principal").value;
      record.remarks = document.getElementById("eval-remarks").value;

      FP.client.from("office_evaluations").upsert([record]).then(function(r){
        saveBtn.disabled = false;
        saveBtn.textContent = "Save evaluation";
        if(r.error){
          FP.toast.error("Could not save: " + r.error.message);
          return;
        }
        FP.toast.success("Office evaluation saved successfully");
      });
    });
  }
})();
