/* =========================================================
   fp-closing-merit.js — loads public.closing_merit_records and
   renders it as a sourced table. Shared by the "View all
   universities" modal (index.html / pathways.html) and
   rankings.html. Requires js/fp-client.js to have already run.

   This is deliberately separate from fp-merit.js:
   fp-merit.js       = the WEIGHTAGE FORMULA (how merit is calculated)
   fp-closing-merit.js = the ACTUAL CUTOFF a real cycle closed at
   Neither one substitutes for the other.
   ========================================================= */

window.FP = window.FP || {};

(function(){

  FP.CLOSING_MERIT = [];

  /** Loads all active closing_merit_records rows into FP.CLOSING_MERIT. */
  FP.loadClosingMerit = function loadClosingMerit(){
    if(!FP.client){
      return Promise.reject(new Error("FP.client not available — js/fp-client.js must load first."));
    }
    return FP.client.from("closing_merit_records").select("*").eq("active", true).order("display_order")
      .then(function(r){
        if(r.error) throw r.error;
        FP.CLOSING_MERIT = r.data || [];
        return FP.CLOSING_MERIT;
      });
  };

  /** All closing-merit rows for one institute, matched by name (case-insensitive). */
  FP.getClosingMeritForInstituteName = function(name){
    var key = String(name || "").trim().toLowerCase();
    if(!key) return [];
    return FP.CLOSING_MERIT.filter(function(row){
      return String(row.university_name_raw || "").trim().toLowerCase() === key;
    });
  };

  /**
   * Loose program-name match — used by rankings.html to attach a
   * closing-merit figure to a QS-ranked subject entry, where the
   * CSV's program label ("BS Computer Science") won't exactly
   * equal the subset label ("Computer Science"). Substring match
   * both directions, case-insensitive.
   */
  /**
   * Loose program-name match — used by rankings.html to attach a
   * closing-merit figure to a QS-ranked subject entry, where the
   * CSV's program label ("BS Computer Science") won't exactly
   * equal the subset label ("Computer Science"). Normalizes away
   * spaces/punctuation first (so "Cyber Security" matches
   * "Cybersecurity"), then substring-matches both directions.
   */
  function normalize(s){
    return String(s || "").toLowerCase().replace(/[^a-z0-9]/g, "");
  }

  FP.findClosingMeritMatch = function(instituteName, subsetLabel){
    var rows = FP.getClosingMeritForInstituteName(instituteName);
    if(!rows.length) return null;
    var needle = normalize(subsetLabel);
    if(!needle) return null;
    return rows.find(function(row){
      var prog = normalize(row.program);
      return prog.indexOf(needle) !== -1 || needle.indexOf(prog) !== -1;
    }) || null;
  };

  var SOURCE_LABEL = {
    official: "OFFICIAL",
    third_party: "THIRD-PARTY",
    not_found: "NOT AVAILABLE"
  };

  FP.renderClosingMeritBadge = function(sourceType){
    var cls = "cm-badge cm-badge-" + (sourceType || "not_found").replace(/_/g, "-");
    var label = SOURCE_LABEL[sourceType] || "UNVERIFIED";
    return '<span class="' + cls + '">' + label + '</span>';
  };

  FP.renderClosingMeritRow = function(row){
    if(row.source_type === "not_found" || row.closing_merit_percentage === null){
      return (
        '<div class="cm-row cm-row-empty">' +
          '<div class="cm-row-main"><span class="cm-program">' + escapeHtml(row.program) + '</span></div>' +
          FP.renderClosingMeritBadge(row.source_type) +
        '</div>'
      );
    }
    return (
      '<div class="cm-row">' +
        '<div class="cm-row-main">' +
          '<span class="cm-program">' + escapeHtml(row.program) + (row.campus ? ' <span class="cm-campus">(' + escapeHtml(row.campus) + ')</span>' : '') + '</span>' +
          '<span class="cm-pct">' + row.closing_merit_percentage + '%</span>' +
        '</div>' +
        '<div class="cm-row-meta">' +
          FP.renderClosingMeritBadge(row.source_type) +
          '<span class="cm-status">' + escapeHtml(row.data_status) + '</span>' +
          (row.source_url ? '<a class="cm-source" href="' + escapeHtml(row.source_url) + '" target="_blank" rel="noopener">Source \u2197</a>' : '') +
        '</div>' +
        (row.notes ? '<p class="cm-notes">' + escapeHtml(row.notes) + '</p>' : '') +
      '</div>'
    );
  };

  /** Inline block used inside the "View all universities" modal. */
  FP.renderClosingMeritSectionForInstitute = function(instituteName){
    var rows = FP.getClosingMeritForInstituteName(instituteName);
    if(!rows.length){
      return '<p class="merit-none">No 2025 closing-merit data collected yet for this institute.</p>';
    }
    return '<div class="cm-inline-section">' + rows.map(FP.renderClosingMeritRow).join("") + '</div>';
  };

  function escapeHtml(str){
    return String(str).replace(/[&<>"']/g, function(c){
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;" }[c];
    });
  }

})();
