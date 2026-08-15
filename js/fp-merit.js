/* =========================================================
   fp-merit.js — loads public.merit_formulas and renders it as
   weight bars / cards. Shared by merit.html (the dedicated
   guide) and the inline "View all universities" modals on
   index.html and pathways.html. Requires js/fp-client.js to
   have already run.
   ========================================================= */

window.FP = window.FP || {};

(function(){

  FP.MERIT_FORMULAS = [];

  /** Loads all active merit_formulas rows into FP.MERIT_FORMULAS. */
  FP.loadMeritFormulas = function loadMeritFormulas(){
    if(!FP.client){
      return Promise.reject(new Error("FP.client not available — js/fp-client.js must load first."));
    }
    return FP.client.from("merit_formulas").select("*").eq("active", true).order("display_order")
      .then(function(r){
        if(r.error) throw r.error;
        FP.MERIT_FORMULAS = r.data || [];
        return FP.MERIT_FORMULAS;
      });
  };

  /** All formula rows for one institute, matched by name (case-insensitive). */
  FP.getMeritFormulasForInstituteName = function(name){
    var key = String(name || "").trim().toLowerCase();
    if(!key) return [];
    return FP.MERIT_FORMULAS.filter(function(row){
      return String(row.institute_name_raw || "").trim().toLowerCase() === key;
    });
  };

  var BAR_COLORS = ["var(--violet)", "var(--green)", "var(--amber)", "var(--red)", "#5C9DF0", "#C77DD9"];

  /** "NET 75%; HSSC 15%; SSC 10%" -> [{label:'NET', pct:75}, ...] */
  FP.parseWeightages = function(text){
    if(!text) return [];
    return text.split(";").map(function(part){
      var m = part.trim().match(/^(.+?)\s+(\d+(?:\.\d+)?)\s*%$/);
      if(!m) return null;
      return { label: m[1].trim(), pct: parseFloat(m[2]) };
    }).filter(Boolean);
  };

  FP.renderWeightBar = function(weightagesText){
    var segs = FP.parseWeightages(weightagesText);
    if(!segs.length){
      return '<p class="merit-holistic">No fixed percentage formula published \u2014 selection is holistic (test / interview / record review).</p>';
    }
    var bar = segs.map(function(s, i){
      return '<span class="merit-bar-seg" style="width:' + s.pct + '%; background:' + BAR_COLORS[i % BAR_COLORS.length] + ';" title="' + escapeHtml(s.label) + ' ' + s.pct + '%"></span>';
    }).join("");
    var legend = segs.map(function(s, i){
      return '<span class="merit-legend-item"><span class="merit-legend-dot" style="background:' + BAR_COLORS[i % BAR_COLORS.length] + ';"></span>' + escapeHtml(s.label) + ' ' + s.pct + '%</span>';
    }).join("");
    return '<div class="merit-bar">' + bar + '</div><div class="merit-legend">' + legend + '</div>';
  };

  FP.renderMeritCard = function(row){
    var title = row.program_scope || row.basis || "General";
    return (
      '<div class="merit-card">' +
        '<div class="merit-card-head">' +
          '<h4>' + escapeHtml(title) + '</h4>' +
          (row.confidence ? '<span class="merit-conf-badge merit-conf-' + escapeHtml(String(row.confidence).toLowerCase().replace(/[^a-z]/g, "-")) + '">' + escapeHtml(row.confidence) + ' confidence</span>' : '') +
        '</div>' +
        FP.renderWeightBar(row.weightages_text) +
        '<p class="merit-formula-text">' + escapeHtml(row.formula_text) + '</p>' +
        '<div class="merit-meta">' +
          (row.accepted_tests ? '<span>Test/exam: ' + escapeHtml(row.accepted_tests) + '</span>' : '') +
          (row.effective_year ? '<span>As of ' + escapeHtml(row.effective_year) + '</span>' : '') +
        '</div>' +
        (row.notes ? '<p class="merit-notes">' + escapeHtml(row.notes) + '</p>' : '') +
        (row.source_url ? '<a class="merit-source" href="' + escapeHtml(row.source_url) + '" target="_blank" rel="noopener">Source \u2197</a>' : '') +
      '</div>'
    );
  };

  /** Inline block used inside the "View all universities" modals. */
  FP.renderMeritSectionForInstitute = function(instituteName){
    var rows = FP.getMeritFormulasForInstituteName(instituteName);
    if(!rows.length){
      return '<p class="merit-none">Merit formula not in the database yet for this institute.</p>';
    }
    return '<div class="merit-inline-section">' + rows.map(FP.renderMeritCard).join("") + '</div>';
  };

  function escapeHtml(str){
    return String(str).replace(/[&<>"']/g, function(c){
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;" }[c];
    });
  }

})();
