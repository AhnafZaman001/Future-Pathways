/* =========================================================
   rankings.js — drives rankings.html off window.RANKING_DATA.
   Pure client-side, no Supabase — this is curated reference
   data, not user data.
   ========================================================= */

(function(){
  var DATA = window.RANKING_DATA;
  var fieldEl = document.getElementById("rk-field");
  var subsetEl = document.getElementById("rk-subset");
  var resultsEl = document.getElementById("rk-results");

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
    if(!field || !subsetEl.value){ resultsEl.innerHTML = ""; return; }
    render(field, subsetEl.value);
  });

  function render(field, subsetName){
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
      html += '<div class="rk-list">' + ranked.map(rowHtml).join("") + '</div>';
    }

    if(field.dataNote){
      html += '<p class="rk-data-note">' + esc(field.dataNote) + '</p>';
    }

    if(field.alsoOffered && field.alsoOffered.length){
      html += '<div class="rk-also"><h3>Also offered at</h3><p>' + field.alsoOffered.map(esc).join(" &middot; ") + '</p></div>';
    }

    html += '</div>';
    resultsEl.innerHTML = html;
  }

  function rowHtml(entry){
    var link = entry.sourceUrl ? '<a href="' + esc(entry.sourceUrl) + '" target="_blank" rel="noopener">' + esc(entry.source) + '</a>' : esc(entry.source);
    return '<div class="rk-row">' +
      '<div class="rk-rank">' + entry.rank + '</div>' +
      '<div class="rk-row-body">' +
        '<div class="rk-uni-name">' + esc(entry.name) + '</div>' +
        '<div class="rk-detail">' + esc(entry.detail) + '</div>' +
        '<div class="rk-source">SOURCE: ' + link + '</div>' +
      '</div>' +
    '</div>';
  }

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }
})();
