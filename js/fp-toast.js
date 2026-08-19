/* =========================================================
   fp-toast.js — Non-intrusive, theme-aware Toast notifications
   Replaces native browser alert() with smooth, animated toasts.
   ========================================================= */

window.FP = window.FP || {};

(function(){
  var container = null;

  function ensureContainer(){
    if(container && document.body.contains(container)) return container;
    container = document.createElement("div");
    container.className = "fp-toast-container";
    container.setAttribute("aria-live", "polite");
    document.body.appendChild(container);
    return container;
  }

  function show(type, message, duration){
    ensureContainer();
    var toast = document.createElement("div");
    toast.className = "fp-toast fp-toast-" + type;

    var iconMap = {
      success: "&#10003;",
      error: "&#10005;",
      info: "&#8505;",
      loading: '<span class="fp-toast-spinner"></span>'
    };

    toast.innerHTML =
      '<div class="fp-toast-icon">' + (iconMap[type] || "&#8505;") + '</div>' +
      '<div class="fp-toast-content">' + String(message || "") + '</div>' +
      '<button type="button" class="fp-toast-close" aria-label="Close">&times;</button>';

    container.appendChild(toast);

    // Force reflow for entrance transition
    void toast.offsetWidth;
    toast.classList.add("is-visible");

    var isSettled = false;
    function dismiss(){
      if(isSettled) return;
      isSettled = true;
      toast.classList.remove("is-visible");
      toast.classList.add("is-hiding");
      setTimeout(function(){
        if(toast.parentNode) toast.parentNode.removeChild(toast);
      }, 250);
    }

    toast.querySelector(".fp-toast-close").addEventListener("click", dismiss);

    if(duration !== 0 && type !== "loading"){
      var autoTime = duration || (type === "error" ? 4500 : 3000);
      setTimeout(dismiss, autoTime);
    }

    return {
      dismiss: dismiss,
      update: function(newType, newMessage, newDuration){
        toast.className = "fp-toast fp-toast-" + newType + " is-visible";
        toast.querySelector(".fp-toast-icon").innerHTML = iconMap[newType] || "&#8505;";
        toast.querySelector(".fp-toast-content").textContent = newMessage;
        if(newDuration !== 0 && newType !== "loading"){
          setTimeout(dismiss, newDuration || 3000);
        }
      }
    };
  }

  FP.toast = {
    success: function(msg, duration){ return show("success", msg, duration); },
    error: function(msg, duration){ return show("error", msg, duration); },
    info: function(msg, duration){ return show("info", msg, duration); },
    loading: function(msg){ return show("loading", msg, 0); }
  };
})();
