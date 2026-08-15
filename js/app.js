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

  function init(){
    Counsellor.UI.populateSelect(fieldSelect, Counsellor.FIELDS);
    Counsellor.UI.populateSelect(areaSelect, Counsellor.AREAS);
    form.addEventListener("submit", handleSubmit);
    form.addEventListener("reset", handleReset);
  }

  function handleSubmit(e){
    e.preventDefault();
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
  }

  function handleReset(){
    resultsSection.hidden = true;
    Counsellor.UI.clearFieldErrors(form);
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
