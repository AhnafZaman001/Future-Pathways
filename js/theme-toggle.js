/* =========================================================
   theme-toggle.js — dark/light theme switch, shared by every
   page. The actual token values live in styles/base.css under
   [data-theme="light"]; this file only ever sets/reads/persists
   the data-theme attribute and updates the toggle button's label.

   The FIRST theme application (avoiding a flash of the wrong
   theme on load) happens separately, via a tiny inline script at
   the very top of each page's <head> — before any CSS loads —
   since this file can't run early enough on its own. This file
   handles everything after that: the actual click-to-switch
   behavior.
   ========================================================= */

window.ThemeToggle = window.ThemeToggle || {};

(function(){
  var STORAGE_KEY = "kips-theme";

  function getStored(){
    try { return localStorage.getItem(STORAGE_KEY); } catch(e){ return null; }
  }
  function setStored(v){
    try { localStorage.setItem(STORAGE_KEY, v); } catch(e){}
  }

  function current(){
    return document.documentElement.getAttribute("data-theme") === "light" ? "light" : "dark";
  }

  function apply(theme){
    if(theme === "light"){
      document.documentElement.setAttribute("data-theme", "light");
    } else {
      document.documentElement.removeAttribute("data-theme");
    }
  }

  function updateButton(btn){
    if(!btn) return;
    var theme = current();
    var label = btn.querySelector(".theme-toggle-label");
    if(label) label.textContent = theme === "light" ? "Light" : "Dark";
    btn.setAttribute("aria-label", theme === "light" ? "Switch to dark theme" : "Switch to light theme");
  }

  function init(){
    var btn = document.getElementById("themeToggle");
    if(!btn) return;
    updateButton(btn);
    btn.addEventListener("click", function(){
      var next = current() === "light" ? "dark" : "light";
      apply(next);
      setStored(next);
      updateButton(btn);
    });
  }

  ThemeToggle.init = init;

  if(document.readyState === "loading"){
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
