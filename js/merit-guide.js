/* =========================================================
   merit-guide.js — controller for merit.html. Requires
   js/fp-client.js and js/fp-merit.js to have already run.
   ========================================================= */

(function(){
  var searchInput    = document.getElementById("meritSearch");
  var searchBtn      = document.getElementById("meritSearchBtn");
  var pathwayFilter  = document.getElementById("meritPathwayFilter");
  var testFilter      = document.getElementById("meritTestFilter");
  var listEl          = document.getElementById("meritList");
  var countEl        = document.getElementById("meritResultsCount");

  FP.requireAuth().then(function(result){
    if(!result) return; // requireAuth already redirected to login.html
    document.body.style.visibility = "visible";

    var emailEl = document.getElementById("fp-user-email");
    if(emailEl && result.session) emailEl.textContent = result.session.user.email;

    var logoutBtn = document.getElementById("fp-logout");
    if(logoutBtn) logoutBtn.addEventListener("click", function(){ FP.signOut(); });

    listEl.innerHTML = '<p class="merit-empty-state">Loading merit formulas\u2026</p>';

    FP.loadMeritFormulas().then(function(){
      populateTestFilter();
      render();
    }).catch(function(err){
      console.error(err);
      listEl.innerHTML = '<p class="merit-empty-state">Couldn\u2019t load merit data. Check your connection and reload.</p>';
    });
  });

  function populateTestFilter(){
    var tests = {};
    FP.MERIT_FORMULAS.forEach(function(row){
      (row.accepted_tests || "").split(/[\/,]/).forEach(function(t){
        t = t.trim();
        if(t) tests[t] = true;
      });
    });
    Object.keys(tests).sort().forEach(function(t){
      var opt = document.createElement("option");
      opt.value = t.toLowerCase();
      opt.textContent = t;
      testFilter.appendChild(opt);
    });
  }

  [searchInput, pathwayFilter, testFilter].forEach(function(el){
    el.addEventListener("input", render);
    el.addEventListener("change", render);
  });

  searchBtn.addEventListener("click", render);
  searchInput.addEventListener("keydown", function(e){
    if(e.key === "Enter"){ e.preventDefault(); render(); }
  });

  function render(){
    var q = searchInput.value.trim().toLowerCase();
    var pathway = pathwayFilter.value;
    var test = testFilter.value;

    var filtered = FP.MERIT_FORMULAS.filter(function(row){
      if(pathway !== "all" && row.pathway !== pathway) return false;
      if(test !== "all" && !(row.accepted_tests || "").toLowerCase().includes(test)) return false;
      if(q && !(row.institute_name_raw || "").toLowerCase().includes(q)) return false;
      return true;
    });

    var groups = {};
    var order = [];
    filtered.forEach(function(row){
      var key = row.institute_name_raw;
      if(!groups[key]){ groups[key] = []; order.push(key); }
      groups[key].push(row);
    });

    countEl.textContent = order.length + " institute" + (order.length === 1 ? "" : "s") + " \u00b7 " + filtered.length + " formula" + (filtered.length === 1 ? "" : "s");

    if(order.length === 0){
      listEl.innerHTML = '<p class="merit-empty-state">No matching institutes. Try a different search or filter.</p>';
      return;
    }

    listEl.innerHTML = order.map(function(name){
      var rows = groups[name];
      var pathwayLabel = rows[0].pathway === "medical" ? "Medical" : "Engineering / General";
      return (
        '<div class="merit-institute-group">' +
          '<h3>' + escapeHtml(name) + '<span class="merit-institute-pathway-tag">' + pathwayLabel + '</span></h3>' +
          rows.map(FP.renderMeritCard).join("") +
        '</div>'
      );
    }).join("");
  }

  function escapeHtml(str){
    return String(str).replace(/[&<>"']/g, function(c){
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;" }[c];
    });
  }
})();
