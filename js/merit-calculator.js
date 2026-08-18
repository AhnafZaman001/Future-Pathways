/* =========================================================
   merit-calculator.js — controller for merit-calculator.html.
   Pure client-side arithmetic against window.MERIT_CALCULATORS
   (js/merit-calculator-data.js); no Supabase read needed for the
   calculation itself, only for the auth gate.
   ========================================================= */

(function(){
  var selectEl       = document.getElementById("calcUniversitySelect");
  var formulaCardEl  = document.getElementById("calcFormulaCard");
  var resultCardEl    = document.getElementById("calcResultCard");

  var DATA = window.MERIT_CALCULATORS || [];

  // Deliberately not using FP.requireAuth() -- this page never reads
  // role, same reasoning as pathways.html/merit.html (see those
  // files' boot comments). getSession() resolves from local storage
  // in the common case, no network round-trip.
  FP.client.auth.getSession().then(function(r){
    if(!r.data.session){ window.location.href = "login.html"; return; }
    document.body.style.visibility = "visible";

    var logoutBtn = document.getElementById("fp-logout");
    if(logoutBtn) logoutBtn.addEventListener("click", function(){ FP.signOut(); });

    init();
  });

  function init(){
    DATA.forEach(function(cfg, i){
      var opt = document.createElement("option");
      opt.value = String(i);
      opt.textContent = cfg.university + " \u2014 " + cfg.variantLabel;
      selectEl.appendChild(opt);
    });

    selectEl.addEventListener("change", function(){
      resultCardEl.innerHTML = "";
      var idx = selectEl.value;
      if(idx === ""){ formulaCardEl.innerHTML = ""; return; }
      renderFormula(DATA[Number(idx)]);
    });
  }

  function renderFormula(cfg){
    var fieldsHtml = cfg.fields.map(function(f){
      if(f.type === "marks"){
        return (
          '<label>' + esc(f.label) + ' (out of ' + f.maxMarks + ')' +
            '<input type="number" min="0" max="' + f.maxMarks + '" step="0.01" data-field="' + esc(f.key) + '" placeholder="e.g. 150">' +
          '</label>'
        );
      }
      return (
        '<label>' + esc(f.label) +
          '<input type="number" min="0" max="100" step="0.01" data-field="' + esc(f.key) + '" placeholder="e.g. 85">' +
        '</label>'
      );
    }).join("");

    formulaCardEl.innerHTML =
      '<div class="fp-card">' +
        '<h3 class="fp-step-title" style="font-size:1.05rem;">' + esc(cfg.university) + ' \u2014 ' + esc(cfg.variantLabel) + '</h3>' +
        '<p class="fp-step-desc">Formula: ' + esc(cfg.formulaText) + '</p>' +
        (cfg.notes ? '<p class="merit-notes" style="margin-bottom:16px;">' + esc(cfg.notes) + '</p>' : '') +
        '<div class="fp-grid-2">' + fieldsHtml + '</div>' +
        '<button type="button" class="btn-primary" id="calcComputeBtn" style="margin-top:16px;">Calculate my merit</button>' +
        '<p class="cm-source" style="margin-top:12px;">SOURCE: <a href="' + esc(cfg.sourceUrl) + '" target="_blank" rel="noopener">' + esc(cfg.sourceLabel) + '</a></p>' +
      '</div>';

    document.getElementById("calcComputeBtn").addEventListener("click", function(){
      compute(cfg);
    });
  }

  function compute(cfg){
    var inputs = formulaCardEl.querySelectorAll("[data-field]");
    var values = {};
    var hasError = false;

    inputs.forEach(function(input){ input.classList.remove("field-error"); });

    cfg.fields.forEach(function(f){
      var input = formulaCardEl.querySelector('[data-field="' + f.key + '"]');
      var raw = input.value.trim();
      if(raw === ""){
        input.classList.add("field-error");
        hasError = true;
        return;
      }
      var num = parseFloat(raw);
      var max = f.type === "marks" ? f.maxMarks : 100;
      if(isNaN(num) || num < 0 || num > max){
        input.classList.add("field-error");
        hasError = true;
        return;
      }
      values[f.key] = f.type === "marks" ? (num / f.maxMarks) * 100 : num;
    });

    if(hasError){
      resultCardEl.innerHTML = '<div class="fp-card"><p class="fp-error">Check the highlighted field' +
        (formulaCardEl.querySelectorAll(".field-error").length > 1 ? "s" : "") +
        ' \u2014 enter a value within the allowed range.</p></div>';
      return;
    }

    var aggregate = 0;
    var breakdown = cfg.fields.map(function(f){
      var contribution = (values[f.key] * f.weight) / 100;
      aggregate += contribution;
      return { label: f.label, pct: values[f.key], weight: f.weight, contribution: contribution };
    });

    resultCardEl.innerHTML =
      '<div class="fp-card">' +
        '<p class="fp-step-desc" style="margin-bottom:4px;">Your ' + esc(cfg.university) + ' aggregate</p>' +
        '<p style="font-family:var(--font-mono); font-weight:700; font-size:2.4rem; color:var(--violet-text); margin:0 0 16px;">' + aggregate.toFixed(2) + '%</p>' +
        '<div class="fp-review-section"><h4>Breakdown</h4>' +
          breakdown.map(function(b){
            return '<div class="fp-review-row"><span>' + esc(b.label) + ' \u2014 ' + b.pct.toFixed(1) + '% \u00d7 ' + b.weight + '%</span><span>' + b.contribution.toFixed(2) + ' pts</span></div>';
          }).join("") +
        '</div>' +
        '<p class="merit-notes">This is the formula\u2019s output, not a promise of admission \u2014 compare it against last year\u2019s closing merit for your specific program on the <a href="rankings.html">University Explorer</a> page.</p>' +
      '</div>';
  }

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;" }[c];
    });
  }
})();
