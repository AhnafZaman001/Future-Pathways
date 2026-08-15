/* =========================================================
   fp-app.js — Future Pathways multi-step form.
   Talks to Supabase via js/fp-client.js. No build step.
   ========================================================= */

(function(){
  var STEPS = ["profile", "pathway", "careers", "institutes", "faculties", "additional", "review"];
  var STEP_LABELS = {
    profile: "Student information",
    pathway: "Pathway",
    careers: "Programs & career interests",
    institutes: "Institute preferences",
    faculties: "Faculty preferences",
    additional: "Additional information",
    review: "Review & submit"
  };

  var state = {
    session: null,
    studentId: null,
    stepIndex: 0,
    profile: { student_name:"", father_name:"", father_profession:"", contact:"", discipline:"", section:"", roll_number:"", matric_marks:"", first_year_marks:"" },
    pathway: null,               // 'engineering' | 'medical'
    careerIds: [],                // selected career_options ids
    customCareer: "",
    institutes: [],               // master data, filtered by pathway
    faculties: [],
    instituteGroups: [],          // [[id|null x5], ...]
    instituteCustom: [],          // [[text x5], ...] used when an "Other" institute is picked
    facultyGroups: [],
    facultyCustom: [],
    additionalInfo: "",
    futurePathwayId: null,
    status: null,                 // 'draft' | 'submitted' | null (no row yet)
    saving: false
  };

  function groupCount(){ return state.pathway === "medical" ? 2 : 4; }

  function emptyGroups(n){
    var g = [];
    for(var i=0;i<n;i++){ g.push([null,null,null,null,null]); }
    return g;
  }
  function emptyCustom(n){
    var g = [];
    for(var i=0;i<n;i++){ g.push(["","","","",""]); }
    return g;
  }

  // ---------------------------------------------------------
  // Boot: auth check, load profile + existing draft/submission
  // ---------------------------------------------------------
  FP.requireAuth().then(function(result){
    if(!result) return; // requireAuth already redirected to login.html
    state.session = result.session;
    state.studentId = result.session.user.id;
    document.getElementById("fp-user-email").textContent = result.session.user.email;

    return Promise.all([
      loadProfile(),
      loadFuturePathway(),
      loadMasterData()
    ]).then(function(){
      render();
    });
  }).catch(function(err){
    console.error(err);
  });

  document.getElementById("fp-logout").addEventListener("click", function(){
    FP.signOut();
  });

  function loadProfile(){
    return FP.client.from("students").select("*").eq("id", state.studentId).maybeSingle()
      .then(function(r){
        if(r.error){ console.error(r.error); return; }
        if(r.data){
          Object.keys(state.profile).forEach(function(k){
            if(r.data[k] !== null && r.data[k] !== undefined) state.profile[k] = r.data[k];
          });
        }
      });
  }

  function loadFuturePathway(){
    return FP.client.from("future_pathways").select("*")
      .eq("student_id", state.studentId)
      .order("created_at", { ascending:false })
      .limit(1).maybeSingle()
      .then(function(r){
        if(r.error){ console.error(r.error); return; }
        if(!r.data) return;
        state.futurePathwayId = r.data.id;
        state.status = r.data.status;
        state.pathway = r.data.pathway;
        state.additionalInfo = r.data.additional_information || "";
        state.instituteGroups = emptyGroups(groupCount());
        state.instituteCustom = emptyCustom(groupCount());
        state.facultyGroups = emptyGroups(groupCount());
        state.facultyCustom = emptyCustom(groupCount());
        return loadPreferences();
      });
  }

  function loadPreferences(){
    return Promise.all([
      FP.client.from("student_institute_preferences").select("*").eq("future_pathway_id", state.futurePathwayId),
      FP.client.from("student_faculty_preferences").select("*").eq("future_pathway_id", state.futurePathwayId),
      FP.client.from("student_program_preferences").select("*").eq("future_pathway_id", state.futurePathwayId)
    ]).then(function(results){
      var inst = results[0].data || [];
      var fac = results[1].data || [];
      var prog = results[2].data || [];
      inst.forEach(function(row){
        var gi = row.preference_group - 1, ri = row.rank - 1;
        if(state.instituteGroups[gi]){
          state.instituteGroups[gi][ri] = row.institute_id;
          state.instituteCustom[gi][ri] = row.custom_institute_name || "";
        }
      });
      fac.forEach(function(row){
        var gi = row.preference_group - 1, ri = row.rank - 1;
        if(state.facultyGroups[gi]){
          state.facultyGroups[gi][ri] = row.faculty_id;
          state.facultyCustom[gi][ri] = row.custom_faculty_name || "";
        }
      });
      state.careerIds = prog.filter(function(p){ return p.program_id; }).map(function(p){ return p.program_id; });
      var custom = prog.find(function(p){ return p.custom_program_name; });
      state.customCareer = custom ? custom.custom_program_name : "";
    });
  }

  function loadMasterData(){
    return Promise.all([
      FP.client.from("institutes").select("*").eq("active", true).order("display_order"),
      FP.client.from("fp_faculties").select("*").eq("active", true).order("display_order"),
      FP.client.from("career_options").select("*").eq("active", true).order("display_order")
    ]).then(function(results){
      state.allInstitutes = results[0].data || [];
      state.allFaculties = results[1].data || [];
      state.allCareers = results[2].data || [];
    });
  }

  // ---------------------------------------------------------
  // Render
  // ---------------------------------------------------------
  function render(){
    renderProgress();
    renderStatusBanner();
    var step = STEPS[state.stepIndex];
    var container = document.getElementById("fp-step-container");
    container.innerHTML = RENDERERS[step]();
    bindStepEvents(step);

    document.getElementById("fp-back").style.visibility = state.stepIndex === 0 ? "hidden" : "visible";
    var nextBtn = document.getElementById("fp-next");
    nextBtn.textContent = step === "review" ? (state.status === "submitted" ? "Already submitted" : "Submit") : "Save & Continue";
    nextBtn.disabled = state.status === "submitted";
  }

  function renderProgress(){
    var wrap = document.getElementById("fp-progress");
    wrap.innerHTML = STEPS.map(function(s, i){
      var cls = i < state.stepIndex ? "is-done" : (i === state.stepIndex ? "is-current" : "");
      return '<div class="fp-progress-step ' + cls + '"></div>';
    }).join("");
    document.getElementById("fp-progress-label").textContent =
      "Step " + (state.stepIndex+1) + " of " + STEPS.length + " — " + STEP_LABELS[STEPS[state.stepIndex]];
  }

  function renderStatusBanner(){
    var el = document.getElementById("fp-status-banner");
    if(state.status === "submitted"){
      el.innerHTML = '<div class="fp-status-banner submitted">Your Future Pathways form has been submitted. It is locked for editing — contact your counsellor for changes.</div>';
    } else if(state.status === "draft"){
      el.innerHTML = '<div class="fp-status-banner draft">You have a saved draft. Progress is saved automatically as you move through the steps.</div>';
    } else {
      el.innerHTML = "";
    }
  }

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }

  var RENDERERS = {
    profile: function(){
      var p = state.profile;
      return '<h2 class="fp-step-title">Student information</h2>' +
        '<p class="fp-step-desc">We\'ve filled in what we already know — check it over.</p>' +
        '<div class="fp-form">' +
          '<div class="fp-grid-2">' +
            field("student_name", "Full name", p.student_name) +
            field("father_name", "Father\'s name", p.father_name) +
          '</div>' +
          '<div class="fp-grid-2">' +
            field("father_profession", "Father\'s profession", p.father_profession) +
            field("contact", "Contact number", p.contact) +
          '</div>' +
          '<div class="fp-grid-2">' +
            field("discipline", "Discipline", p.discipline) +
            field("section", "Section", p.section) +
          '</div>' +
          '<div class="fp-grid-2">' +
            field("roll_number", "Roll number", p.roll_number) +
            field("matric_marks", "Matric marks", p.matric_marks, "number") +
          '</div>' +
          field("first_year_marks", "FSc Part 1 marks", p.first_year_marks, "number") +
        '</div>';

      function field(key, label, val, type){
        return '<label>' + label +
          '<input type="' + (type||"text") + '" data-field="' + key + '" value="' + esc(val) + '" required>' +
          '</label>';
      }
    },

    pathway: function(){
      return '<h2 class="fp-step-title">Choose your pathway</h2>' +
        '<p class="fp-step-desc">This determines which institutes, faculties, and programs you\'ll see next.</p>' +
        '<div class="fp-pathway-options">' +
          pathwayCard("engineering", "Engineering / Non-Medical", "Engineering, Computer & IT, and related programs.") +
          pathwayCard("medical", "Medical / Health Sciences", "MBBS, BDS, Pharm D, DPT, and related programs.") +
        '</div>';

      function pathwayCard(val, title, desc){
        var sel = state.pathway === val ? "is-selected" : "";
        return '<button type="button" class="fp-pathway-card ' + sel + '" data-pathway="' + val + '">' +
          '<h3>' + title + '</h3><p>' + desc + '</p></button>';
      }
    },

    careers: function(){
      if(!state.pathway) return '<p class="fp-step-desc">Pick a pathway first.</p>';
      var opts = state.allCareers.map(function(c){
        var checked = state.careerIds.indexOf(c.id) > -1 ? "checked" : "";
        return '<label class="fp-checkbox-item"><input type="checkbox" data-career="' + c.id + '" ' + checked + '> ' + esc(c.name) + '</label>';
      }).join("");
      return '<h2 class="fp-step-title">Programs &amp; career interests</h2>' +
        '<p class="fp-step-desc">Select every option you\'re considering, alongside your main pathway.</p>' +
        '<div class="fp-checkbox-grid">' + opts + '</div>' +
        '<label style="margin-top:16px;">If "BS (Hons) Leading to ___" applies, specify' +
          '<input type="text" id="fp-custom-career" value="' + esc(state.customCareer) + '"></label>';
    },

    institutes: function(){
      if(!state.pathway) return '<p class="fp-step-desc">Pick a pathway first.</p>';
      var options = state.allInstitutes.filter(function(i){ return i.pathway === state.pathway; });
      ensureGroupArrays();
      return '<h2 class="fp-step-title">Institute preferences</h2>' +
        '<p class="fp-step-desc">Rank up to 5 institutes in each group, 1 = highest preference. No repeats within a group.</p>' +
        prefGroupsHTML("institute", options, state.instituteGroups, state.instituteCustom);
    },

    faculties: function(){
      if(!state.pathway) return '<p class="fp-step-desc">Pick a pathway first.</p>';
      var options = state.allFaculties.filter(function(f){ return f.pathway === state.pathway; });
      ensureGroupArrays();
      return '<h2 class="fp-step-title">Faculty preferences</h2>' +
        '<p class="fp-step-desc">Rank up to 5 faculties/programs in each group, 1 = highest preference. No repeats within a group.</p>' +
        prefGroupsHTML("faculty", options, state.facultyGroups, state.facultyCustom);
    },

    additional: function(){
      return '<h2 class="fp-step-title">Additional information</h2>' +
        '<p class="fp-step-desc">Anything else your counsellor should know.</p>' +
        '<textarea id="fp-additional" rows="6" style="width:100%; font-family:var(--font-body); padding:10px 12px; border:1px solid var(--line-strong); border-radius:var(--radius-sm);">' + esc(state.additionalInfo) + '</textarea>';
    },

    review: function(){
      var p = state.profile;
      var careerNames = state.allCareers.filter(function(c){ return state.careerIds.indexOf(c.id) > -1; }).map(function(c){ return c.name; });
      if(state.customCareer) careerNames.push(state.customCareer);

      var instHtml = groupsReviewHtml(state.instituteGroups, state.instituteCustom, state.allInstitutes.filter(function(i){ return i.pathway===state.pathway; }));
      var facHtml = groupsReviewHtml(state.facultyGroups, state.facultyCustom, state.allFaculties.filter(function(f){ return f.pathway===state.pathway; }));

      return '<h2 class="fp-step-title">Review</h2>' +
        '<p class="fp-step-desc">Check everything before submitting. You cannot edit after you submit.</p>' +
        reviewSection("Student information", [
          ["Name", p.student_name], ["Father's name", p.father_name], ["Father's profession", p.father_profession],
          ["Contact", p.contact], ["Discipline", p.discipline], ["Section", p.section],
          ["Roll number", p.roll_number], ["Matric marks", p.matric_marks], ["FSc Part 1 marks", p.first_year_marks]
        ]) +
        reviewSection("Pathway", [["Selected", state.pathway === "medical" ? "Medical / Health Sciences" : "Engineering / Non-Medical"]]) +
        reviewSection("Programs & careers", [["Selected", careerNames.join(", ") || "\u2014"]]) +
        '<div class="fp-review-section"><h4>Institute preferences</h4>' + instHtml + '</div>' +
        '<div class="fp-review-section"><h4>Faculty preferences</h4>' + facHtml + '</div>' +
        reviewSection("Additional information", [["Notes", state.additionalInfo || "\u2014"]]);

      function reviewSection(title, rows){
        return '<div class="fp-review-section"><h4>' + title + '</h4>' +
          rows.map(function(r){ return '<div class="fp-review-row"><span>' + r[0] + '</span><span>' + esc(r[1] || "\u2014") + '</span></div>'; }).join("") +
          '</div>';
      }
    }
  };

  function ensureGroupArrays(){
    var n = groupCount();
    if(state.instituteGroups.length !== n){ state.instituteGroups = emptyGroups(n); state.instituteCustom = emptyCustom(n); }
    if(state.facultyGroups.length !== n){ state.facultyGroups = emptyGroups(n); state.facultyCustom = emptyCustom(n); }
  }

  function prefGroupsHTML(kind, options, groups, customArr){
    return groups.map(function(ranks, gi){
      var dupes = findDupes(ranks);
      var ranksHtml = ranks.map(function(val, ri){
        var isDupe = val && dupes.indexOf(val) > -1;
        var selectHtml = '<select data-kind="' + kind + '" data-group="' + gi + '" data-rank="' + ri + '">' +
          '<option value="">\u2014 select \u2014</option>' +
          options.map(function(o){
            var sel = (val === o.id) ? "selected" : "";
            return '<option value="' + o.id + '" ' + sel + '>' + esc(o.name) + (o.location ? " (" + esc(o.location) + ")" : "") + '</option>';
          }).join("") +
        '</select>';
        var customName = options.find(function(o){ return o.id === val; });
        var showCustom = customName && customName.name === "Other";
        var customInput = showCustom ?
          '<input type="text" placeholder="Name it" data-kind="' + kind + '-custom" data-group="' + gi + '" data-rank="' + ri + '" value="' + esc(customArr[gi][ri]) + '" style="max-width:160px;">' : "";
        return '<div class="fp-pref-rank ' + (isDupe?"has-dupe":"") + '"><span class="fp-rank-badge">' + (ri+1) + '</span>' + selectHtml + customInput + '</div>';
      }).join("");
      return '<div class="fp-pref-group"><h4>Preference group ' + (gi+1) + '</h4><div class="fp-pref-ranks">' + ranksHtml + '</div></div>';
    }).join("");
  }

  function findDupes(arr){
    var seen = {}, dupes = [];
    arr.forEach(function(v){
      if(!v) return;
      if(seen[v]) dupes.push(v); else seen[v] = true;
    });
    return dupes;
  }

  function groupsReviewHtml(groups, customArr, options){
    return groups.map(function(ranks, gi){
      var names = ranks.map(function(v, ri){
        if(!v) return null;
        var o = options.find(function(x){ return x.id === v; });
        var name = o ? o.name : v;
        if(name === "Other" && customArr[gi][ri]) name = customArr[gi][ri];
        return (ri+1) + ". " + name;
      }).filter(Boolean).join(", ");
      return '<div class="fp-review-row"><span>Group ' + (gi+1) + '</span><span>' + esc(names || "\u2014") + '</span></div>';
    }).join("");
  }

  // ---------------------------------------------------------
  // Event binding per step
  // ---------------------------------------------------------
  function bindStepEvents(step){
    var container = document.getElementById("fp-step-container");

    if(step === "profile"){
      container.querySelectorAll("[data-field]").forEach(function(input){
        input.addEventListener("input", function(){ state.profile[input.dataset.field] = input.value; });
      });
    }
    if(step === "pathway"){
      container.querySelectorAll("[data-pathway]").forEach(function(btn){
        btn.addEventListener("click", function(){
          state.pathway = btn.dataset.pathway;
          state.instituteGroups = emptyGroups(groupCount());
          state.instituteCustom = emptyCustom(groupCount());
          state.facultyGroups = emptyGroups(groupCount());
          state.facultyCustom = emptyCustom(groupCount());
          render();
        });
      });
    }
    if(step === "careers"){
      container.querySelectorAll("[data-career]").forEach(function(cb){
        cb.addEventListener("change", function(){
          var id = cb.dataset.career;
          if(cb.checked){ if(state.careerIds.indexOf(id) === -1) state.careerIds.push(id); }
          else { state.careerIds = state.careerIds.filter(function(x){ return x !== id; }); }
        });
      });
      var customEl = document.getElementById("fp-custom-career");
      if(customEl) customEl.addEventListener("input", function(){ state.customCareer = customEl.value; });
    }
    if(step === "institutes" || step === "faculties"){
      container.querySelectorAll("select[data-kind]").forEach(function(sel){
        sel.addEventListener("change", function(){
          var gi = +sel.dataset.group, ri = +sel.dataset.rank;
          var target = sel.dataset.kind === "institute" ? state.instituteGroups : state.facultyGroups;
          target[gi][ri] = sel.value || null;
          render();
        });
      });
      container.querySelectorAll("input[data-kind$='-custom']").forEach(function(inp){
        inp.addEventListener("input", function(){
          var gi = +inp.dataset.group, ri = +inp.dataset.rank;
          var target = inp.dataset.kind.indexOf("institute") === 0 ? state.instituteCustom : state.facultyCustom;
          target[gi][ri] = inp.value;
        });
      });
    }
    if(step === "additional"){
      document.getElementById("fp-additional").addEventListener("input", function(e){ state.additionalInfo = e.target.value; });
    }
  }

  // ---------------------------------------------------------
  // Validation per step
  // ---------------------------------------------------------
  function validateStep(step){
    if(step === "profile"){
      var p = state.profile;
      var required = ["student_name","father_name","contact","discipline","roll_number","matric_marks","first_year_marks"];
      var missing = required.filter(function(k){ return !p[k] && p[k] !== 0; });
      if(missing.length) return "Please fill in all required student information fields.";
    }
    if(step === "pathway" && !state.pathway) return "Please select a pathway to continue.";
    if(step === "institutes" || step === "faculties"){
      var groups = step === "institutes" ? state.instituteGroups : state.facultyGroups;
      for(var i=0;i<groups.length;i++){
        if(findDupes(groups[i]).length) return "Remove duplicate selections within preference group " + (i+1) + ".";
      }
    }
    return null;
  }

  // ---------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------
  function ensureFuturePathwayRow(){
    if(state.futurePathwayId) return Promise.resolve(state.futurePathwayId);
    return FP.client.from("future_pathways").insert([{
      student_id: state.studentId, pathway: state.pathway || "engineering", status: "draft"
    }]).select().single().then(function(r){
      if(r.error){ throw r.error; }
      state.futurePathwayId = r.data.id;
      state.status = "draft";
      return state.futurePathwayId;
    });
  }

  function saveProfile(){
    var record = Object.assign({ id: state.studentId }, state.profile);
    return FP.client.from("students").upsert([record]).then(function(r){
      if(r.error) throw r.error;
    });
  }

  function saveDraftShell(){
    return ensureFuturePathwayRow().then(function(id){
      return FP.client.from("future_pathways").update({
        pathway: state.pathway, additional_information: state.additionalInfo
      }).eq("id", id).then(function(r){ if(r.error) throw r.error; });
    });
  }

  function savePreferences(){
    if(!state.futurePathwayId) return Promise.resolve();
    var fpId = state.futurePathwayId;
    var instRows = [];
    state.instituteGroups.forEach(function(ranks, gi){
      ranks.forEach(function(val, ri){
        if(!val) return;
        var opt = state.allInstitutes.find(function(o){ return o.id === val; });
        instRows.push({
          future_pathway_id: fpId, preference_group: gi+1, rank: ri+1,
          institute_id: val,
          custom_institute_name: (opt && opt.name === "Other") ? (state.instituteCustom[gi][ri] || null) : null
        });
      });
    });
    var facRows = [];
    state.facultyGroups.forEach(function(ranks, gi){
      ranks.forEach(function(val, ri){
        if(!val) return;
        var opt = state.allFaculties.find(function(o){ return o.id === val; });
        facRows.push({
          future_pathway_id: fpId, preference_group: gi+1, rank: ri+1,
          faculty_id: val,
          custom_faculty_name: (opt && opt.name === "Other") ? (state.facultyCustom[gi][ri] || null) : null
        });
      });
    });
    var progRows = state.careerIds.map(function(id, i){
      return { future_pathway_id: fpId, rank: i+1, program_id: id };
    });
    if(state.customCareer){
      progRows.push({ future_pathway_id: fpId, rank: progRows.length+1, custom_program_name: state.customCareer });
    }

    return Promise.all([
      FP.client.from("student_institute_preferences").delete().eq("future_pathway_id", fpId),
      FP.client.from("student_faculty_preferences").delete().eq("future_pathway_id", fpId),
      FP.client.from("student_program_preferences").delete().eq("future_pathway_id", fpId)
    ]).then(function(){
      var ops = [];
      if(instRows.length) ops.push(FP.client.from("student_institute_preferences").insert(instRows));
      if(facRows.length) ops.push(FP.client.from("student_faculty_preferences").insert(facRows));
      if(progRows.length) ops.push(FP.client.from("student_program_preferences").insert(progRows));
      return Promise.all(ops);
    });
  }

  function persistStep(step){
    if(step === "profile") return saveProfile().then(saveDraftShell);
    if(step === "pathway" || step === "additional") return saveDraftShell();
    if(step === "institutes" || step === "faculties" || step === "careers") return saveDraftShell().then(savePreferences);
    return Promise.resolve();
  }

  function submit(){
    return FP.client.from("future_pathways").update({
      status: "submitted", submitted_at: new Date().toISOString()
    }).eq("id", state.futurePathwayId).then(function(r){
      if(r.error) throw r.error;
      state.status = "submitted";
    });
  }

  // ---------------------------------------------------------
  // Nav
  // ---------------------------------------------------------
  document.getElementById("fp-back").addEventListener("click", function(){
    if(state.stepIndex > 0){ state.stepIndex--; render(); }
  });

  document.getElementById("fp-next").addEventListener("click", function(){
    if(state.status === "submitted" || state.saving) return;
    var step = STEPS[state.stepIndex];
    var err = validateStep(step);
    if(err){ alert(err); return; }

    state.saving = true;
    var nextBtn = document.getElementById("fp-next");
    nextBtn.disabled = true;

    persistStep(step).then(function(){
      if(step === "review"){
        return submit();
      }
      state.stepIndex++;
    }).then(function(){
      state.saving = false;
      render();
    }).catch(function(e){
      console.error(e);
      state.saving = false;
      nextBtn.disabled = false;
      alert("Something went wrong saving that step: " + (e.message || e));
    });
  });
})();
