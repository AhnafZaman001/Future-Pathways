/* =========================================================
   student-faculties.js -- "View Student Faculties" admin page.

   Mirrors the priority-cycling feature built for institute
   preferences on admin.html (js/fp-admin.js), but reads
   student_faculty_preferences instead of student_institute_
   preferences. Deliberately kept separate rather than merged
   into fp-admin.js/admin.html -- this is a focused, read-only
   view (no bulk actions, no CSV export, no delete), not another
   copy of the full submissions table.
   ========================================================= */
(function(){
  var submissions = [];       // [{ id, student_id, pathway, status, students: {student_name} }]
  var facultyLookup = {};     // faculty_id -> name
  var facultyByFpId = {};     // future_pathway_id -> faculty name (or custom name) at the CURRENT priorityN
  var priorityN = 1;          // which preference position (1-20) is currently shown

  // ---------------------------------------------------------
  // Same flattened-position math as fp-admin.js: preferences are
  // stored as 4 groups of 5 ranked slots each (2 groups for
  // medical, per groupCount() in fp-app.js) -- 20 total positions
  // for most pathways, 10 for medical.
  // ---------------------------------------------------------
  function groupRankFromPriority(n){
    return { group: Math.floor((n - 1) / 5) + 1, rank: ((n - 1) % 5) + 1 };
  }

  function ordinal(n){
    var rem100 = n % 100;
    if(rem100 >= 11 && rem100 <= 13) return n + "th";
    switch(n % 10){
      case 1: return n + "st";
      case 2: return n + "nd";
      case 3: return n + "rd";
      default: return n + "th";
    }
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

  var authPromise = FP.getSessionAndProfile();

  authPromise.then(function(result){
    if(!result){ window.location.href = "login.html"; return; }

    var role = result.profile ? result.profile.role : "student";
    if(role !== "counsellor" && role !== "admin"){
      window.location.href = "access-denied.html";
      return;
    }

    document.getElementById("fp-logout").addEventListener("click", function(){ FP.signOut(); });

    fetchFaculties();
    fetchSubmissions();
  }).catch(function(e){ console.error(e); });

  // ---------------------------------------------------------
  // Data -- each fetch owns its own failure/retry, same pattern
  // as fp-admin.js's graceful-degradation setup. A failed faculty
  // lookup just means names show blank, not that the whole page
  // breaks; a failed submissions fetch is the one that matters,
  // so it gets a visible retry.
  // ---------------------------------------------------------
  function fetchFaculties(){
    return FP.client.from("fp_faculties").select("id,name").then(function(r){
      if(r.error) throw r.error;
      facultyLookup = {};
      (r.data || []).forEach(function(f){ facultyLookup[f.id] = f.name; });
      return fetchPriorityFaculties();
    }).catch(function(e){
      console.error("Faculty lookup failed to load:", e);
    });
  }

  function fetchSubmissions(){
    return FP.client.from("future_pathways").select("id, student_id, pathway, status, students(student_name)")
      .order("created_at", { ascending:false })
      .then(function(r){
        if(r.error) throw r.error;
        submissions = r.data || [];
        renderTable();
      }).catch(function(e){
        console.error(e);
        FP.toast.error("Couldn't load students. Check your connection and try again.");
      });
  }

  function fetchPriorityFaculties(){
    var gr = groupRankFromPriority(priorityN);
    return FP.client.from("student_faculty_preferences")
      .select("future_pathway_id, faculty_id, custom_faculty_name")
      .eq("preference_group", gr.group).eq("rank", gr.rank)
      .then(function(r){
        if(r.error) throw r.error;
        applyPriorityFaculties(r);
      }).catch(function(e){
        console.error(e);
      });
  }

  function applyPriorityFaculties(r){
    facultyByFpId = {}; // reset -- otherwise switching ranks leaves stale names for students without a preference at the new rank
    (r.data || []).forEach(function(row){
      var name = row.custom_faculty_name || facultyLookup[row.faculty_id] || null;
      if(name) facultyByFpId[row.future_pathway_id] = name;
    });

    var usedNames = Array.from(new Set(Object.values(facultyByFpId))).sort();
    var select = document.getElementById("sf-filter-priority");
    select.innerHTML = '<option value="">All</option>' +
      usedNames.map(function(n){ return '<option value="' + esc(n) + '">' + esc(n) + '</option>'; }).join("");

    document.getElementById("sf-priority-label").textContent = ordinal(priorityN) + " priority faculty";
    document.getElementById("sf-priority-col-label").textContent = ordinal(priorityN) + " Priority Faculty";

    renderTable();
  }

  // ---------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------
  function renderTable(){
    var nameFilter = document.getElementById("sf-filter-name").value.trim().toLowerCase();
    var pathwayFilter = document.getElementById("sf-filter-pathway").value;
    var priorityFilter = document.getElementById("sf-filter-priority").value;

    var rows = submissions.filter(function(s){
      var name = titleCase((s.students && s.students.student_name) || "");
      return (!nameFilter || name.toLowerCase().indexOf(nameFilter) !== -1)
        && (!pathwayFilter || s.pathway === pathwayFilter)
        && (!priorityFilter || facultyByFpId[s.id] === priorityFilter);
    });

    var tbody = document.getElementById("sf-tbody");
    tbody.innerHTML = rows.map(function(s){
      var name = titleCase((s.students && s.students.student_name) || "") || "(no profile yet)";
      var faculty = facultyByFpId[s.id] || "\u2014";
      return '<tr>' +
        '<td><strong>' + esc(name) + '</strong></td>' +
        '<td class="fp-cap">' + esc(s.pathway) + '</td>' +
        '<td>' + esc(faculty) + '</td>' +
        '<td><span class="fp-badge ' + esc(s.status) + '">' + esc(s.status) + '</span></td>' +
      '</tr>';
    }).join("");

    document.getElementById("sf-empty-hint").hidden = rows.length > 0;
  }

  document.getElementById("sf-filter-name").addEventListener("input", renderTable);
  document.getElementById("sf-filter-pathway").addEventListener("change", renderTable);
  document.getElementById("sf-filter-priority").addEventListener("change", renderTable);

  // ---------------------------------------------------------
  // Prev / Next -- steps priorityN backward or forward, wrapping
  // at both ends (20 -> 1 going forward, 1 -> 20 going back).
  // ---------------------------------------------------------
  function stepPriority(delta){
    priorityN = priorityN + delta;
    if(priorityN > 20) priorityN = 1;
    if(priorityN < 1) priorityN = 20;
    document.getElementById("sf-filter-priority").value = ""; // old selection may not exist at the new rank

    var prevBtn = document.getElementById("sf-priority-prev");
    var nextBtn = document.getElementById("sf-priority-next");
    prevBtn.disabled = true; nextBtn.disabled = true;
    fetchPriorityFaculties().finally(function(){
      prevBtn.disabled = false; nextBtn.disabled = false;
    });
  }

  document.getElementById("sf-priority-prev").addEventListener("click", function(){ stepPriority(-1); });
  document.getElementById("sf-priority-next").addEventListener("click", function(){ stepPriority(1); });
})();
