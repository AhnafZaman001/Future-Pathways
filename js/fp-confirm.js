/* =========================================================
   fp-confirm.js — FP.confirm(message) -> Promise<boolean>

   Replaces window.confirm() for anything destructive/irreversible-
   feeling (currently just the reset-submission action). A native
   browser confirm() dialog is unstyled -- shows the raw hostname,
   ignores the app's theme entirely, and looks like Chrome asking
   the question, not the product. This is the same fade+scale
   overlay choreography already proven for the "View all
   universities" modal (force a reflow before adding .is-open so
   the transition actually plays, delay re-applying `hidden` on
   close to match the transition duration) -- reused, not
   reinvented.

   Lives on window.FP so it's usable from any page that loads
   fp-client.js, not just admin.html -- built the dialog once,
   lazily, on first call.
   ========================================================= */

window.FP = window.FP || {};

(function(){
  var overlay, messageEl, okBtn, cancelBtn;
  var resolveFn = null;

  function ensureBuilt(){
    if(overlay) return;
    overlay = document.createElement("div");
    overlay.className = "uni-modal-overlay confirm-modal-overlay";
    overlay.hidden = true;
    overlay.innerHTML =
      '<div class="uni-modal confirm-modal" role="alertdialog" aria-modal="true">' +
        '<p class="confirm-modal-message"></p>' +
        '<div class="confirm-modal-actions">' +
          '<button type="button" class="btn-secondary confirm-modal-cancel">Cancel</button>' +
          '<button type="button" class="btn-primary confirm-modal-ok">OK</button>' +
        '</div>' +
      '</div>';
    document.body.appendChild(overlay);

    messageEl = overlay.querySelector(".confirm-modal-message");
    okBtn = overlay.querySelector(".confirm-modal-ok");
    cancelBtn = overlay.querySelector(".confirm-modal-cancel");

    okBtn.addEventListener("click", function(){ settle(true); });
    cancelBtn.addEventListener("click", function(){ settle(false); });
    overlay.addEventListener("click", function(e){ if(e.target === overlay) settle(false); });
    document.addEventListener("keydown", function(e){
      if(!overlay.hidden && e.key === "Escape") settle(false);
    });
  }

  function settle(result){
    overlay.classList.remove("is-open");
    setTimeout(function(){
      if(!overlay.classList.contains("is-open")) overlay.hidden = true;
    }, 320);
    if(resolveFn){
      var r = resolveFn;
      resolveFn = null;
      r(result);
    }
  }

  FP.confirm = function(message){
    ensureBuilt();
    messageEl.textContent = message;
    overlay.hidden = false;
    void overlay.offsetWidth; // force reflow so the fade/scale transition actually plays
    overlay.classList.add("is-open");
    okBtn.focus();
    return new Promise(function(resolve){
      resolveFn = resolve;
    });
  };
})();
