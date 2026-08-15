/* =========================================================
   ui.js — all DOM reads/writes live here. app.js calls into
   this; nothing here computes merit or filters data itself.
   ========================================================= */

window.Counsellor = window.Counsellor || {};

const STATUS_META = {
  strong:      { label: "Strong chance", badgeClass: "badge-strong",      gaugeColor: "var(--green)" },
  competitive: { label: "Competitive",    badgeClass: "badge-competitive", gaugeColor: "var(--amber)" },
  unlikely:    { label: "Unlikely",        badgeClass: "badge-unlikely",    gaugeColor: "var(--red)" },
  unknown:      { label: "Merit data needed", badgeClass: "badge-unknown",  gaugeColor: "var(--ink-soft)" }
};

Counsellor.UI = {

  populateSelect: function(selectEl, options){
    options.forEach(function(opt){
      const el = document.createElement("option");
      el.value = opt.id;
      el.textContent = opt.label;
      selectEl.appendChild(el);
    });
  },

  clearFieldErrors: function(form){
    form.querySelectorAll(".field-error").forEach(function(el){
      el.classList.remove("field-error");
    });
  },

  markFieldError: function(el){
    el.classList.add("field-error");
  },

  renderScoreStrip: function(container, provisional){
    container.innerHTML = "";

    const items = [
      { label: "Score so far", value: provisional.scoreSoFar + " / 100" },
      { label: "Best case ceiling", value: provisional.ceiling + " / 100" },
      { label: "Entry-test weight pending", value: provisional.pendingWeight + " pts" }
    ];

    items.forEach(function(item){
      const pill = document.createElement("div");
      pill.className = "score-pill";
      pill.innerHTML = '<span class="num">' + item.value + '</span><span class="label">' + item.label + '</span>';
      container.appendChild(pill);
    });
  },

  renderResults: function(container, suggestions, areaLabel){
    container.innerHTML = "";

    if(suggestions.length === 0){
      container.innerHTML =
        '<div class="empty-state">' +
          '<strong>No institutes on file for that field yet.</strong>' +
          'This list comes live from the Supabase <code>institutes</code> table — check that it has active rows for this pathway.' +
        '</div>';
      return;
    }

    let lastAreaMatch = null;

    suggestions.forEach(function(s){
      if(s.isAreaMatch !== lastAreaMatch){
        const divider = document.createElement("p");
        divider.className = "field-hint";
        divider.style.margin = "6px 0 -2px";
        divider.textContent = s.isAreaMatch
          ? "In or near " + areaLabel
          : "Outside your preferred area, but worth a look";
        container.appendChild(divider);
        lastAreaMatch = s.isAreaMatch;
      }
      container.appendChild(Counsellor.UI.buildCard(s));
    });
  },

  buildCard: function(s){
    const meta = STATUS_META[s.status];
    const card = document.createElement("article");
    card.className = "uni-card";

    const showGauge = Counsellor.MERIT_FEATURE_ENABLED;
    const pct = showGauge && s.closingMerit !== null ? Math.min(100, Math.round((s.scoreSoFar / 100) * 100)) : 0;

    const gaugeHtml = showGauge
      ? '<div class="gauge" style="--pct:' + pct + '; --gauge-color:' + meta.gaugeColor + ';">' +
          '<span>' + s.scoreSoFar + '</span>' +
        '</div>'
      : '';

    const badgeHtml = showGauge
      ? '<span class="badge ' + meta.badgeClass + '">' + meta.label + '</span>'
      : '<span class="badge badge-unknown">Merit data pending</span>';

    const categoryLabel = (Counsellor.CATEGORY_LABELS && Counsellor.CATEGORY_LABELS[s.category]) || capitalize(s.category);
    const locationLabel = s.location || "Location not listed";

    card.innerHTML =
      gaugeHtml +
      '<div class="info">' +
        '<h3>' + s.universityName + '</h3>' +
        '<div class="meta">' +
          '<span>' + categoryLabel + '</span>' +
          '<span>&middot; ' + locationLabel + '</span>' +
          (showGauge ? '<span>&middot; Closing merit: ' + (s.closingMerit !== null ? s.closingMerit : "TBD") + '</span>' : '') +
        '</div>' +
      '</div>' +
      badgeHtml;

    return card;
  }
};

function capitalize(str){
  if(!str) return "";
  return str.charAt(0).toUpperCase() + str.slice(1);
}
