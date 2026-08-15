/* =========================================================
   app.js — init + event wiring. Keep this thin: it should
   only call into Counsellor.* modules, not contain logic.
   ========================================================= */

(function(){
  const form            = document.getElementById("intake-form");
  const fieldSelect      = document.getElementById("fieldOfStudy");
  const areaSelect        = document.getElementById("area");
  const resultsSection    = document.getElementById("results-section");
  const resultsName      = document.getElementById("resultsName");
  const scoreStrip        = document.getElementById("scoreStrip");
  const resultsList      = document.getElementById("resultsList");
  const saveStatus        = document.getElementById("saveStatus");

  const submitBtn = form.querySelector(".btn-primary");

  // Tracks the actual fetch state so the modal/UI can tell "still
  // fetching" apart from "fetch finished, zero rows came back" —
  // those need very different messages.
  let institutesLoadState = "loading"; // "loading" | "loaded" | "error"

  function init(){
    Counsellor.UI.populateSelect(fieldSelect, Counsellor.FIELDS);
    Counsellor.UI.populateSelect(areaSelect, Counsellor.AREAS);
    form.addEventListener("submit", handleSubmit);
    form.addEventListener("reset", handleReset);
    initUniModal();
    initEnterToAdvance();
    loadInstitutesWithLoadingState();
    if(typeof FP !== "undefined" && FP.loadMeritFormulas){
      FP.loadMeritFormulas().catch(function(err){ console.error("Merit formulas failed to load:", err); });
    }
  }

  /* ---------------------------------------------------------
     Institute data now comes live from Supabase (see
     Counsellor.loadInstitutes in js/data.js) rather than a
     static array, so it needs to be fetched once at boot.
     The submit button is disabled with a loading label until
     the fetch resolves; on failure it's re-enabled with a
     "Retry loading universities" label so the user isn't stuck.
     --------------------------------------------------------- */
  function loadInstitutesWithLoadingState(){
    institutesLoadState = "loading";
    if(submitBtn){
      submitBtn.disabled = true;
      submitBtn.textContent = "Loading universities\u2026";
    }
    return Counsellor.loadInstitutes().then(function(){
      institutesLoadState = "loaded";
      if(submitBtn){
        submitBtn.disabled = false;
        submitBtn.textContent = "Suggest universities";
      }
    }).catch(function(err){
      institutesLoadState = "error";
      console.error("Failed to load institutes from Supabase:", err);
      if(submitBtn){
        submitBtn.disabled = false;
        submitBtn.textContent = "Retry loading universities";
        submitBtn.dataset.loadFailed = "true";
      }
    });
  }

  /* ---------------------------------------------------------
     Pressing Enter in any field moves to the next fillable
     field instead of doing nothing / submitting early. Readonly
     fields (matricTotal) are skipped. On the last field, Enter
     submits the form.
     --------------------------------------------------------- */
  function initEnterToAdvance(){
    var focusable = Array.prototype.slice.call(
      form.querySelectorAll("input:not([readonly]), select")
    );

    focusable.forEach(function(el, idx){
      el.addEventListener("keydown", function(e){
        if(e.key !== "Enter") return;
        e.preventDefault();

        var next = focusable[idx + 1];
        if(next){
          next.focus();
          if(typeof next.showPicker === "function" && next.tagName === "SELECT"){
            try { next.showPicker(); } catch(err){ /* not supported everywhere, ignore */ }
          }
        } else if(typeof form.requestSubmit === "function"){
          form.requestSubmit();
        } else {
          handleSubmit({ preventDefault: function(){} });
        }
      });
    });
  }

  /* ---------------------------------------------------------
     "View all universities" modal — groups the live
     Counsellor.INSTITUTES (loaded from Supabase) by their
     `pathway` column into Engineering / Medical buckets, same
     grouping fp-app.js uses on pathways.html. Opening the modal
     before the institute fetch resolves shows a loading note.
     --------------------------------------------------------- */
  function initUniModal(){
    const openBtn  = document.getElementById("viewUnisBtn");
    const overlay  = document.getElementById("uniModalOverlay");
    const closeBtn = document.getElementById("uniModalClose");
    const body      = document.getElementById("uniModalBody");
    if(!openBtn || !overlay || !closeBtn || !body) return;

    function open(){
      body.innerHTML = renderUniGroups();
      overlay.hidden = false;
      document.addEventListener("keydown", onKeydown);

      // If institutes never loaded (e.g. opened before the initial
      // fetch settled, or after it failed), retry now and refresh
      // the modal body once it resolves — instead of leaving the
      // modal stuck on its initial render forever.
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

    const all = Counsellor.INSTITUTES || [];
    if(all.length === 0){
      return '<p class="uni-modal-empty">No universities are in the database yet. Run the seed script in Supabase, then reopen this window.</p>';
    }

    const buckets = { "Engineering": [], "Medical": [], "Other": [] };

    all.forEach(function(inst){
      const bucket = inst.pathway === "engineering" ? "Engineering"
                   : inst.pathway === "medical"      ? "Medical"
                   : "Other";
      buckets[bucket].push(inst);
    });

    const order = ["Engineering", "Medical", "Other"];
    return order
      .filter(function(name){ return name !== "Other" || buckets["Other"].length > 0; })
      .map(function(name){
        const entries = buckets[name];
        const listHtml = entries.length
          ? "<ul>" + entries.map(function(inst){
              const meta = inst.location || (inst.campuses && inst.campuses.length ? inst.campuses.join(", ") : "");
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

  function handleSubmit(e){
    e.preventDefault();

    // Institute fetch failed earlier — retry instead of submitting
    // with a stale/empty Counsellor.INSTITUTES list.
    if(submitBtn && submitBtn.dataset.loadFailed === "true"){
      delete submitBtn.dataset.loadFailed;
      loadInstitutesWithLoadingState();
      return;
    }

    Counsellor.UI.clearFieldErrors(form);

    const data = collectFormData();
    const errors = validate(data);

    if(errors.length){
      errors.forEach(function(id){
        Counsellor.UI.markFieldError(document.getElementById(id));
      });
      return;
    }

    const matricPct = Counsellor.toPercent(data.matricObtained, data.matricTotal);
    const fscPct      = Counsellor.toPercent(data.fscObtained, data.fscTotal);
    const provisional = Counsellor.computeProvisionalScore(data.fieldOfStudy, matricPct, fscPct);

    const suggestions = Counsellor.getSuggestions({
      name: data.studentName,
      matricPct: matricPct,
      fscPct: fscPct,
      fieldId: data.fieldOfStudy,
      areaId: data.area
    });

    const areaLabel = (Counsellor.AREAS.find(function(a){ return a.id === data.area; }) || {}).label || data.area;

    resultsName.textContent = data.studentName || "you";
    Counsellor.UI.renderScoreStrip(scoreStrip, provisional);
    Counsellor.UI.renderResults(resultsList, suggestions, areaLabel);

    resultsSection.hidden = false;
    resultsSection.scrollIntoView({ behavior: "smooth", block: "start" });

    saveToDatabase(data, matricPct, fscPct, provisional);
  }

  function saveToDatabase(data, matricPct, fscPct, provisional){
    setSaveStatus("pending", "Saving your record\u2026");

    Counsellor.saveSubmission({
      student_name:        data.studentName,
      matric_obtained:      data.matricObtained,
      matric_total:        data.matricTotal,
      fsc_obtained:        data.fscObtained,
      fsc_total:            data.fscTotal,
      field_of_study:      data.fieldOfStudy,
      area:                data.area,
      matric_pct:          Math.round(matricPct * 10) / 10,
      fsc_pct:              Math.round(fscPct * 10) / 10,
      provisional_score:    provisional.scoreSoFar,
      provisional_ceiling: provisional.ceiling
    }).then(function(result){
      if(result && result.error){
        setSaveStatus("error", "Couldn't save to the database: " + result.error.message);
      } else {
        setSaveStatus("ok", "Saved to the database.");
      }
    }).catch(function(err){
      setSaveStatus("error", "Couldn't save to the database: " + err.message);
    });
  }

  function setSaveStatus(kind, message){
    saveStatus.className = "save-status save-status--" + kind;
    saveStatus.textContent = message;
  }

  function handleReset(){
    resultsSection.hidden = true;
    Counsellor.UI.clearFieldErrors(form);
    saveStatus.textContent = "";
    saveStatus.className = "save-status";
  }

  function collectFormData(){
    return {
      studentName:    document.getElementById("studentName").value.trim(),
      matricObtained: Number(document.getElementById("matricObtained").value),
      matricTotal:    Number(document.getElementById("matricTotal").value),
      fscObtained:    Number(document.getElementById("fscObtained").value),
      fscTotal:        Number(document.getElementById("fscTotal").value),
      fieldOfStudy:    document.getElementById("fieldOfStudy").value,
      area:            document.getElementById("area").value
    };
  }

  function validate(data){
    const errors = [];
    if(!data.studentName) errors.push("studentName");
    if(!data.matricObtained || data.matricObtained < 0) errors.push("matricObtained");
    if(!data.matricTotal || data.matricTotal <= 0 || data.matricObtained > data.matricTotal) errors.push("matricTotal");
    if(!data.fscObtained || data.fscObtained < 0) errors.push("fscObtained");
    if(!data.fscTotal || data.fscTotal <= 0 || data.fscObtained > data.fscTotal) errors.push("fscTotal");
    if(!data.fieldOfStudy) errors.push("fieldOfStudy");
    if(!data.area) errors.push("area");
    return errors;
  }

  document.addEventListener("DOMContentLoaded", init);
})();
