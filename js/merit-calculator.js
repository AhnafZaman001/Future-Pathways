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

  function fieldInputsHtml(f){
    if(f.type === "marks_fixed"){
      return (
        '<label>' + esc(f.label) + ' (out of ' + f.maxMarks + ')' +
          '<input type="number" min="0" max="' + f.maxMarks + '" step="0.01" data-field="' + esc(f.key) + '" data-kind="obtained" placeholder="e.g. 150">' +
        '</label>'
      );
    }
    if(f.type === "marks_variable"){
      return (
        '<div class="calc-marks-pair">' +
          '<label>' + esc(f.label) + ' obtained' +
            '<input type="number" min="0" step="0.01" data-field="' + esc(f.key) + '" data-kind="obtained" placeholder="e.g. 980">' +
          '</label>' +
          '<label>Total marks' +
            '<input type="number" min="1" step="0.01" data-field="' + esc(f.key) + '" data-kind="total" placeholder="e.g. 1100">' +
          '</label>' +
        '</div>'
      );
    }
    // "percent"
    return (
      '<label>' + esc(f.label) +
        '<input type="number" min="0" max="100" step="0.01" data-field="' + esc(f.key) + '" data-kind="obtained" placeholder="e.g. 85">' +
      '</label>'
    );
  }

  function renderFormula(cfg){
    var fieldsHtml = cfg.fields.map(fieldInputsHtml).join("");

    formulaCardEl.innerHTML =
      '<div class="fp-card">' +
        '<h3 class="fp-step-title" style="font-size:1.05rem;">' + esc(cfg.university) + ' \u2014 ' + esc(cfg.variantLabel) + '</h3>' +
        '<p class="fp-step-desc">Formula: ' + esc(cfg.formulaText) + '</p>' +
        (cfg.notes ? '<p class="merit-notes" style="margin-bottom:16px;">' + esc(cfg.notes) + '</p>' : '') +
        '<div class="fp-grid-2">' + fieldsHtml + '</div>' +
        '<button type="button" class="btn-primary" id="calcComputeBtn" style="margin-top:16px;">Calculate my merit</button>' +
      '</div>';

    document.getElementById("calcComputeBtn").addEventListener("click", function(){
      compute(cfg);
    });
  }

  function compute(cfg){
    var allInputs = formulaCardEl.querySelectorAll("[data-field]");
    allInputs.forEach(function(input){ input.classList.remove("field-error"); });

    var values = {};
    var hasError = false;

    function markError(input){ input.classList.add("field-error"); hasError = true; }

    cfg.fields.forEach(function(f){
      if(f.type === "marks_variable"){
        var obtInput  = formulaCardEl.querySelector('[data-field="' + f.key + '"][data-kind="obtained"]');
        var totInput  = formulaCardEl.querySelector('[data-field="' + f.key + '"][data-kind="total"]');
        var obtained  = parseFloat(obtInput.value.trim());
        var total     = parseFloat(totInput.value.trim());
        var fieldOk   = true;

        if(obtInput.value.trim() === "" || isNaN(obtained) || obtained < 0){ markError(obtInput); fieldOk = false; }
        if(totInput.value.trim() === "" || isNaN(total) || total <= 0){ markError(totInput); fieldOk = false; }
        if(fieldOk && obtained > total){ markError(obtInput); markError(totInput); fieldOk = false; }

        if(fieldOk){ values[f.key] = (obtained / total) * 100; }
        return;
      }

      // "percent" or "marks_fixed" -- single input either way
      var input = formulaCardEl.querySelector('[data-field="' + f.key + '"]');
      var raw = input.value.trim();
      if(raw === ""){ markError(input); return; }
      var num = parseFloat(raw);
      var max = f.type === "marks_fixed" ? f.maxMarks : 100;
      if(isNaN(num) || num < 0 || num > max){ markError(input); return; }
      values[f.key] = f.type === "marks_fixed" ? (num / f.maxMarks) * 100 : num;
    });

    if(hasError){
      resultCardEl.innerHTML = '<div class="fp-card"><p class="fp-error">Check the highlighted field' +
        (formulaCardEl.querySelectorAll(".field-error").length > 1 ? "s" : "") +
        ' \u2014 enter a valid value (marks obtained can\u2019t exceed the total).</p></div>';
      return;
    }

    var aggregate = 0;
    cfg.fields.forEach(function(f){
      aggregate += (values[f.key] * f.weight) / 100;
    });

    resultCardEl.innerHTML =
      '<div class="fp-card">' +
        '<p class="fp-step-desc" style="margin-bottom:4px;">Your ' + esc(cfg.university) + ' aggregate</p>' +
        '<p style="font-family:var(--font-mono); font-weight:700; font-size:2.4rem; color:var(--violet-text); margin:0 0 4px;">' + aggregate.toFixed(2) + '%</p>' +
        '<p class="merit-notes">Compare this against last year\u2019s closing merit for your specific program on the <a href="rankings.html">University Explorer</a> page.</p>' +
      '</div>';
  }

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;" }[c];
    });
  }
})();
