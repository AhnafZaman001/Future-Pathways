/* =========================================================
   rankings.js — drives rankings.html off window.RANKING_DATA
   (curated QS/THE reference data) plus, where a real match
   exists, a live 2025 closing-merit figure pulled from
   Supabase's closing_merit_records table via fp-closing-merit.js.
   The ranking content itself stays static/curated; only the
   closing-merit line is live data.
   ========================================================= */

(function(){
  var DATA = window.RANKING_DATA;
  var fieldEl = document.getElementById("rk-field");
  var subsetEl = document.getElementById("rk-subset");
  var resultsEl = document.getElementById("rk-results");
  var lastField = null, lastSubset = null;

  // rankings-data.js uses display-friendly names ("NUST (SEECS)",
  // "GIK Institute (GIKI)") that don't exactly equal the canonical
  // institutes.name / closing_merit_records.university_name_raw
  // values ("NUST", "GIK"). This maps display name -> canonical
  // name so the closing-merit lookup actually finds a match.
  var INSTITUTE_ALIAS = {
    "GIK Institute (GIKI)": "GIK",
    "COMSATS University Islamabad": "COMSATS",
    "NUST (SEECS)": "NUST",
    "University of the Punjab (PUCIT)": "Punjab University/PUCIT"
  };
  function canonicalName(displayName){
    return INSTITUTE_ALIAS[displayName] || displayName;
  }

  if(typeof FP !== "undefined" && FP.loadClosingMerit){
    FP.loadClosingMerit().then(function(){
      if(lastField && lastSubset) render(lastField, lastSubset);
    }).catch(function(err){ console.error("Closing merit records failed to load:", err); });
  }

  Object.keys(DATA).forEach(function(key){
    var opt = document.createElement("option");
    opt.value = key;
    opt.textContent = DATA[key].label;
    fieldEl.appendChild(opt);
  });

  fieldEl.addEventListener("change", function(){
    var field = DATA[fieldEl.value];
    subsetEl.innerHTML = "";
    resultsEl.innerHTML = "";
    lastField = null; lastSubset = null;

    if(!field){
      subsetEl.disabled = true;
      subsetEl.innerHTML = '<option value="">&mdash; Select a field first &mdash;</option>';
      return;
    }
    subsetEl.disabled = false;
    subsetEl.innerHTML = '<option value="">&mdash; Select a specialization &mdash;</option>' +
      field.subsets.map(function(s){ return '<option value="' + esc(s) + '">' + esc(s) + '</option>'; }).join("");
  });

  subsetEl.addEventListener("change", function(){
    var field = DATA[fieldEl.value];
    if(!field || !subsetEl.value){ resultsEl.innerHTML = ""; lastField = null; lastSubset = null; return; }
    render(field, subsetEl.value);
  });

  function render(field, subsetName){
    lastField = field; lastSubset = subsetName;
    var override = field.overrides ? field.overrides[subsetName] : null;
    var ranked = (override === "unranked") ? [] : (override || field.baseRanking);
    var isSubjectSpecific = !!(override && override !== "unranked");

    var html = '<div class="fp-card rk-results-card">';
    html += '<div class="rk-results-head">' +
      '<h2 class="fp-step-title">' + esc(field.label) + ' &mdash; ' + esc(subsetName) + '</h2>' +
      '<span class="rk-count">' + ranked.length + ' RANKED</span>' +
      '</div>';

    if(!isSubjectSpecific && ranked.length){
      html += '<p class="rk-scope-note">Showing ' + esc(field.label).toLowerCase() + '-wide standing &mdash; a ' + esc(subsetName).toLowerCase() + '-specific ranking isn\'t independently published.</p>';
    }

    if(ranked.length === 0){
      html += '<div class="rk-empty">No independently verifiable ranking exists yet for ' + esc(subsetName) + '. We don\'t publish estimated numbers &mdash; check back as more official data is verified.</div>';
    } else {
      html += '<div class="rk-list">' + ranked.map(function(entry){ return rowHtml(entry, subsetName); }).join("") + '</div>';
    }

    if(field.dataNote){
      html += '<p class="rk-data-note">' + esc(field.dataNote) + '</p>';
    }
    if(ranked.some(function(e){ return e.theBand; })){
      html += '<p class="rk-data-note">"THE 2026" badges show that university\'s overall Times Higher Education World University Rankings 2026 band (not subject-specific — THE\'s subject tables aren\'t available for direct citation here), reported via Gulf News\'s coverage of THE\'s release.</p>';
    }
    if(ranked.some(function(e){ return !!closingMeritMatch(e, subsetName); })){
      html += '<p class="rk-data-note">Closing-merit figures shown are the actual 2025 admission cycle cutoff for that program, separate from the QS/THE rankings above — see each figure\'s own source badge.</p>';
    }

    if(field.alsoOffered && field.alsoOffered.length){
      html += '<div class="rk-also"><h3>Also offered at</h3>' +
        '<div class="rk-list">' + field.alsoOffered.map(alsoRowHtml).join("") + '</div>' +
      '</div>';
    }

    if(field.industryReputation){
      html += '<div class="rk-industry">' +
        '<h3>Industry reputation <span class="rk-industry-badge">not a ranking</span></h3>' +
        '<p class="rk-industry-note">' + esc(field.industryReputation.note) + '</p>' +
        '<div class="rk-tags">' + field.industryReputation.names.map(function(n){
          return '<span class="rk-tag">' + esc(n) + '</span>';
        }).join("") + '</div>' +
      '</div>';
    }

    html += '</div>';
    resultsEl.innerHTML = html;
  }

  function closingMeritMatch(entry, subsetName){
    if(typeof FP === "undefined" || !FP.findClosingMeritMatch) return null;
    return FP.findClosingMeritMatch(canonicalName(entry.name), subsetName);
  }

  function closingMeritHtml(entry, subsetName){
    var match = closingMeritMatch(entry, subsetName);
    if(!match || match.closing_merit_percentage === null) return "";
    var sameName = normalize(match.program) === normalize(subsetName);
    return '<div class="rk-cm">' +
      '<span class="rk-cm-label">2025 CLOSING MERIT</span> ' +
      '<span class="rk-cm-pct">' + match.closing_merit_percentage + '%</span> ' +
      FP.renderClosingMeritBadge(match.source_type) +
      (sameName ? '' : ' <span class="rk-cm-program">(listed as &ldquo;' + esc(match.program) + '&rdquo;)</span>') +
      (match.campus ? ' <span class="rk-cm-campus">' + esc(match.campus) + '</span>' : '') +
    '</div>';
  }

  function normalize(s){
    return String(s == null ? "" : s).toLowerCase().replace(/[^a-z0-9]/g, "");
  }

  function rowHtml(entry, subsetName){
    var link = entry.sourceUrl ? '<a href="' + esc(entry.sourceUrl) + '" target="_blank" rel="noopener">' + esc(entry.source) + '</a>' : esc(entry.source);
    var theBandHtml = entry.theBand ?
      '<div class="rk-the-band"><span class="rk-the-label">THE 2026</span> ' + esc(entry.theBand) + '</div>' : "";
    return '<div class="rk-row">' +
      '<div class="rk-rank">' + entry.rank + '</div>' +
      '<div class="rk-row-body">' +
        '<div class="rk-uni-name">' + esc(entry.name) + '</div>' +
        '<div class="rk-detail">' + esc(entry.detail) + '</div>' +
        theBandHtml +
        closingMeritHtml(entry, subsetName) +
        '<div class="rk-source">SOURCE: ' + link + '</div>' +
      '</div>' +
    '</div>';
  }

  function alsoRowHtml(name){
    return '<div class="rk-row rk-row-also">' +
      '<div class="rk-rank rk-rank-also">&mdash;</div>' +
      '<div class="rk-row-body">' +
        '<div class="rk-uni-name">' + esc(name) + '</div>' +
        '<div class="rk-detail">Offers this program &mdash; no independently verified rank yet</div>' +
      '</div>' +
    '</div>';
  }

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }
})();
