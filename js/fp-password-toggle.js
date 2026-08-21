/* =========================================================
   fp-password-toggle.js — adds a show/hide eye button to every
   password input on the page. Auto-runs on load; no markup
   changes needed per-page beyond including this script after
   the password <input> exists in the DOM.

   Wraps each input[type="password"] in a .fp-password-field div
   (styles/components.css) and inserts a button that flips the
   input's type between "password" and "text". Purely a client-
   side UX affordance -- doesn't touch validation, autocomplete,
   or how the value is submitted.
   ========================================================= */

(function(){
  var EYE_OPEN =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
    'stroke-linecap="round" stroke-linejoin="round">' +
    '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8Z"/>' +
    '<circle cx="12" cy="12" r="3"/></svg>';

  var EYE_CLOSED =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
    'stroke-linecap="round" stroke-linejoin="round">' +
    '<path d="M17.94 17.94A10.94 10.94 0 0 1 12 20c-7 0-11-8-11-8a20.3 20.3 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a20.4 20.4 0 0 1-3.22 4.44M14.12 14.12a3 3 0 1 1-4.24-4.24"/>' +
    '<path d="M1 1l22 22"/></svg>';

  function wrap(input){
    if(input.closest(".fp-password-field")) return; // already wrapped

    var wrapper = document.createElement("div");
    wrapper.className = "fp-password-field";
    input.parentNode.insertBefore(wrapper, input);
    wrapper.appendChild(input);

    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "fp-password-toggle";
    btn.setAttribute("aria-label", "Show password");
    btn.setAttribute("aria-pressed", "false");
    btn.tabIndex = 0;
    btn.innerHTML = EYE_OPEN;
    wrapper.appendChild(btn);

    btn.addEventListener("click", function(){
      var showing = input.type === "text";
      input.type = showing ? "password" : "text";
      btn.innerHTML = showing ? EYE_OPEN : EYE_CLOSED;
      btn.setAttribute("aria-label", showing ? "Show password" : "Hide password");
      btn.setAttribute("aria-pressed", showing ? "false" : "true");
      // Keep focus + cursor position in the field itself, not the button,
      // so someone can toggle visibility mid-typing without losing their place.
      input.focus();
    });
  }

  function init(){
    document.querySelectorAll('input[type="password"]').forEach(wrap);
  }

  if(document.readyState === "loading"){
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
