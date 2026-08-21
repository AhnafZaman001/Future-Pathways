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
  var cityEl = document.getElementById("rk-city");
  var resultsEl = document.getElementById("rk-results");
  var lastField = null, lastSubset = null;

  // rankings-data.js uses display-friendly names ("NUST (SEECS)",
  // "GIK Institute (GIKI)") that don't exactly equal the canonical
  // institutes.name / closing_merit_records.university_name_raw
  // values ("NUST", "GIK"). This maps display name -> canonical
  // name so the closing-merit lookup actually finds a match.
  var INSTITUTE_ALIAS = {
    // Variants used in rankings-data.js -> canonical DB name
    "GIK Institute (GIKI)": "GIK",
    "COMSATS University Islamabad": "COMSATS",
    "NUST (SEECS)": "NUST",
    "University of the Punjab (PUCIT)": "Punjab University/PUCIT",
    "Punjab University College of IT (PUCIT)": "Punjab University/PUCIT",
    "ITU Lahore": "ITU",
    "Namal University": "Namal",
    "IBA Karachi": "IBA",
    "LUMS (SAHSOL)": "LUMS",
    "GCU Lahore": "Government College University Lahore",
    "University of the Punjab": "Punjab University/PUCIT",
    "University of Agriculture Faisalabad": "University of Agriculture Faisalabad",
    // alsoOffered entries carry full parenthetical explanations for display --
    // strip to the short DB name for city-filter lookup
    "FAST-NUCES (widely regarded as Pakistan\u2019s leading dedicated computing university by employer surveys \u2014 not separately QS subject-ranked at a confirmed position)": "FAST-NUCES",
    "Aga Khan University (AKU Karachi \u2014 QS Medicine 201\u2013250 globally, 2026; Pakistan\u2019s only internationally accredited medical school)": "Aga Khan University",
    "Habib University (social sciences, 400+ globally QS 2026)": "Habib University",
    "NUST Business School": "NUST",
    "University of Karachi (School of Law)": "University of Karachi",
  };
  // City data for institutes in rankings-data.js that are NOT in the
  // live institutes DB -- hardcoded so city filter works without a
  // SQL migration. Checked as a fallback in institutePresentInCity().
  var EXTRA_CITY_DATA = {
    "UMT Lahore":                               ["Lahore"],
    "Shifa College of Medicine":                ["Islamabad"],
    "CMH Lahore Medical College":               ["Lahore"],
    "Army Medical College Rawalpindi":          ["Rawalpindi"],
    "Sheikh Zayed Medical College":             ["Rahim Yar Khan"],
    "DG Khan Medical College":                  ["Dera Ghazi Khan"],
    "Muhammad Nawaz Shareef University of Agriculture Multan": ["Multan"],
    "Sindh Agriculture University Tandojam":    ["Tandojam"],
    "University of Agriculture Peshawar":       ["Peshawar"],
    "SZABIST Islamabad / Karachi":              ["Islamabad","Karachi"],
    "Government College University Lahore":     ["Lahore"],
    "Superior University College of Law":       ["Lahore"],
    "University of the Punjab Law College":     ["Lahore"],
    "International Islamic University Islamabad": ["Islamabad"],
    "Forman Christian College":                 ["Lahore"],
    "Pir Mehr Ali Shah Arid Agriculture University Rawalpindi": ["Rawalpindi"],
    "University of Veterinary & Animal Sciences Lahore": ["Lahore"],
    "Habib University":                         ["Karachi"],
    "University of Karachi (School of Law)":    ["Karachi"],
    "GCU Lahore":                               ["Lahore"],
    "Bahauddin Zakariya University":            ["Multan"],
    "University of Peshawar":                   ["Peshawar"],
    // Medical colleges added in medical_colleges_complete.sql
    "Dow Medical College (DUHS)":                              ["Karachi"],
    "Jinnah Sindh Medical University (JSMU)":                  ["Karachi"],
    "Shaheed Mohtarma Benazir Bhutto Medical College (Lyari)": ["Karachi"],
    "Karachi Metropolitan University (KMDC)":                  ["Karachi"],
    "Liaquat University of Medical & Health Sciences (LUMHS)": ["Jamshoro"],
    "Peoples University of Medical & Health Sciences (PUMHS)": ["Nawabshah"],
    "Ghulam Muhammad Mahar Medical College":                   ["Sukkur"],
    "Muhammad Medical College":                                ["Mirpurkhas"],
    "Bilawal Medical College Jamshoro":                        ["Jamshoro"],
    "Chandka Medical College (Larkana)":                       ["Larkana"],
    "Isra University (Hyderabad)":                             ["Hyderabad"],
    "Khyber Medical College (KMC)":                            ["Peshawar"],
    "Khyber Girls Medical College":                            ["Peshawar"],
    "Bacha Khan Medical College":                              ["Mardan"],
    "Gajju Khan Medical College":                              ["Swabi"],
    "Nowshera Medical College":                                ["Nowshera"],
    "Ayub Medical College (Abbottabad)":                       ["Abbottabad"],
    "Saidu Medical College (Swat)":                            ["Swat"],
    "Gomal Medical College (DIKhan)":                          ["Dera Ismail Khan"],
    "Bannu Medical College":                                   ["Bannu"],
    "Rehman Medical College (Peshawar)":                       ["Peshawar"],
    "Frontier Medical College (Abbottabad)":                   ["Abbottabad"],
    "Bolan Medical College (Quetta)":                          ["Quetta"],
    "Loralai Medical College":                                 ["Loralai"],
    "Makran Medical College (Turbat)":                         ["Turbat"],
    "Jhalawan Medical College (Khuzdar)":                      ["Khuzdar"],
    "Azad Jammu & Kashmir Medical College (Muzaffarabad)":     ["Muzaffarabad"],
    "Mohtarma Benazir Bhutto Shaheed Medical College (Mirpur)":["Mirpur"],
    "Poonch Medical College (Rawalakot)":                      ["Rawalakot"],
  };
  function canonicalName(displayName){
    return INSTITUTE_ALIAS[displayName] || displayName;
  }

  if(typeof FP !== "undefined" && FP.loadClosingMerit){
    FP.loadClosingMerit().then(function(){
      if(lastField && lastSubset) render(lastField, lastSubset);
    }).catch(function(err){ console.error("Closing merit records failed to load:", err); });
  }

  /* ---------------------------------------------------------
     City filter -- a third filter alongside Field/Specialization
     in the SAME selector card, refining the SAME ranked results
     (not a separate search tool). Uses institutes.location +
     institutes.campuses (real data) mapped by canonical name so
     it lines up with the curated rankings-data.js entries above.
     ----------------------------------------------------------- */
  var cityByInstitute = {}; // canonical institute name -> [cities]
  var institutesPromise; // set inside init(); reused by subsetEl's change handler to know when cityByInstitute is ready

  function institutePresentInCity(name, city){
    if(!city) return true; // no city filter active
    var canonical = canonicalName(name);
    var cities = cityByInstitute[canonical] || EXTRA_CITY_DATA[name] || EXTRA_CITY_DATA[canonical];
    return !!(cities && cities.indexOf(city) !== -1);
  }

  // ---------------------------------------------------------
  // Auth gate -- this page was previously reachable by anyone
  // with the URL, signed in or not (the only page on the site
  // without one). Same lightweight getSession() check used on
  // merit.html/merit-calculator.html: no profile round-trip
  // needed since this page doesn't branch on role, just on
  // "is anyone signed in at all". Everything that touches the
  // DOM now waits on this instead of firing at script-load time.
  // ---------------------------------------------------------
  FP.client.auth.getSession().then(function(r){
    if(!r.data.session){ window.location.href = "login.html"; return; }
    document.body.style.visibility = "visible";

    var logoutBtn = document.getElementById("fp-logout");
    if(logoutBtn) logoutBtn.addEventListener("click", function(){ FP.signOut(); });

    init();
  });

  function init(){
    institutesPromise = (FP && FP.client)
      ? FP.client.from("institutes").select("name, location, campuses").eq("active", true)
      : Promise.resolve({ data: [] });

    institutesPromise.then(function(r){
      var all = r.data || [];
      all.forEach(function(inst){
        var cities = [];
        if(inst.location) cities.push(inst.location);
        (inst.campuses || []).forEach(function(c){ if(c) cities.push(c); });
        cityByInstitute[inst.name] = cities;
      });
      // Default/pre-selection state: every city with ANY institute in
      // the DB, regardless of field. Narrowed down to just the cities
      // relevant to the current Field/Specialization the moment one is
      // chosen -- see syncCityOptions(), called from the subsetEl
      // change handler below.
      var citySet = {};
      all.forEach(function(inst){
        (cityByInstitute[inst.name] || []).forEach(function(c){ citySet[c] = true; });
      });
      var sortedCities = Object.keys(citySet).sort();
      cityEl.innerHTML = '<option value="">All cities</option>' +
        sortedCities.map(function(c){ return '<option value="' + esc(c) + '">' + esc(c) + '</option>'; }).join("");
    }).catch(function(err){ console.error("Institutes (for city filter) failed to load:", err); });

    cityEl.addEventListener("change", function(){
      if(lastField && lastSubset) render(lastField, lastSubset);
    });

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
        subsetEl.innerHTML = '<option value="">Select a field first</option>';
        return;
      }
      subsetEl.disabled = false;
      subsetEl.innerHTML = '<option value="">Select a specialization</option>' +
        field.subsets.map(function(s){ return '<option value="' + esc(s) + '">' + esc(s) + '</option>'; }).join("");
    });

    subsetEl.addEventListener("change", function(){
      var field = DATA[fieldEl.value];
      if(!field || !subsetEl.value){ resultsEl.innerHTML = ""; lastField = null; lastSubset = null; return; }
      // Wait on institutesPromise (usually already resolved by the
      // time someone gets this far) so cityByInstitute is populated
      // before we decide which cities are actually relevant.
      (institutesPromise || Promise.resolve()).then(function(){
        syncCityOptions(field, subsetEl.value);
        render(field, subsetEl.value);
      });
    });
  }

  // Every raw name (ranked + alsoOffered + industryReputation) for a
  // given field/subset combo, override-aware -- the exact same set
  // render() turns into result cards. Shared so the city dropdown and
  // the results list can never drift out of sync with each other.
  function fieldEntries(field, subsetName){
    var override = field.overrides ? field.overrides[subsetName] : null;
    var allRanked = (override === "unranked") ? [] : (override || field.baseRanking);
    var names = allRanked.map(function(entry){ return entry.name; });
    (field.alsoOffered || []).forEach(function(n){ names.push(n); });
    if(field.industryReputation){
      field.industryReputation.names.forEach(function(n){ names.push(n); });
    }
    return names;
  }

  // Rebuilds the City dropdown to only the cities where at least one
  // university actually offers the selected Field/Specialization --
  // previously it always listed every city with any institute at all
  // in the DB, most of which had nothing to do with the current
  // selection and just produced "No universities found" dead ends.
  function syncCityOptions(field, subsetName){
    var citySet = {};
    fieldEntries(field, subsetName).forEach(function(name){
      var canonical = canonicalName(name);
      var cities = cityByInstitute[canonical] || EXTRA_CITY_DATA[name] || EXTRA_CITY_DATA[canonical] || [];
      cities.forEach(function(c){ citySet[c] = true; });
    });
    var cities = Object.keys(citySet).sort();

    var prevValue = cityEl.value;
    cityEl.innerHTML = '<option value="">All cities</option>' +
      cities.map(function(c){ return '<option value="' + esc(c) + '">' + esc(c) + '</option>'; }).join("");
    // Keep the previously-picked city selected if it's still a valid
    // option for the new field/subset; otherwise fall back to "All
    // cities" rather than silently pointing at a city with zero results.
    cityEl.value = cities.indexOf(prevValue) !== -1 ? prevValue : "";
  }

  function render(field, subsetName){
    lastField = field; lastSubset = subsetName;
    var city = cityEl.value;

    // Collect all universities -- ranked entries + alsoOffered +
    // industryReputation names -- into one flat, deduplicated list,
    // filtered by city. No divisions, no numbers, no badges.
    var seen = {};
    var all = [];

    function addName(name){
      // Strip trailing parentheticals used for display context
      // (e.g. "FAST-NUCES (widely regarded as...)" -> "FAST-NUCES")
      var clean = name.replace(/\s*\([^)]{20,}\)$/, "").trim();
      var key = clean.toLowerCase();
      if(!seen[key] && institutePresentInCity(name, city)){
        seen[key] = true;
        all.push(clean);
      }
    }

    fieldEntries(field, subsetName).forEach(addName);

    var html = '<div class="fp-card rk-results-card">';
    html += '<h2 class="fp-step-title">' +
      esc(field.label) + ' | ' + esc(subsetName) +
      (city ? ' | ' + esc(city) : '') +
    '</h2>';

    if(all.length === 0){
      html += '<p class="rk-empty">No universities found' + (city ? ' in ' + esc(city) : '') + ' for this program.</p>';
    } else {
      html += '<ul class="rk-flat-list">' +
        all.map(function(name){
          return '<li class="rk-flat-item">' + esc(name) + '</li>';
        }).join("") +
      '</ul>';
    }

    html += '</div>';
    resultsEl.innerHTML = html;
  }

  function closingMeritMatch(){ return null; } // retained so nothing else breaks
  function closingMeritHtml(){ return ""; }
  function normalize(s){ return String(s==null?"":s).toLowerCase().replace(/[^a-z0-9]/g,""); }
  function rowHtml(){ return ""; }
  function alsoRowHtml(){ return ""; }

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }
})();
