/* =========================================================
   fp-chat-assistant.js -- floating chat widget backed by the
   chat-assistant Supabase Edge Function (Groq, rate-limited).
   (redeploy trigger)

   Counsellor/admin only -- the edge function itself also enforces
   this server-side, so this client-side check is a UX nicety, not
   the actual security boundary.

   Two modes:
   - General: FAQ-style questions (merit formulas, how the site
     works). No context sent.
   - Student-scoped: call FP.chatAssistant.openForStudent(studentId,
     studentName) to open the widget pre-loaded with a context chip;
     every message sent while that chip is showing includes the
     studentId so the edge function can ground answers in that
     student's real submitted preferences.
   ========================================================= */
(function(){
  var FUNCTION_NAME = "chat-assistant";
  var panel, launcher, messagesEl, inputEl, sendBtn, contextChipEl;
  var activeStudentId = null;
  var activeStudentName = null;
  var sending = false;

  function esc(s){
    return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
      return {"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c];
    });
  }

  function buildWidget(){
    launcher = document.createElement("button");
    launcher.type = "button";
    launcher.className = "fp-chat-launcher";
    launcher.setAttribute("aria-label", "Open assistant");
    launcher.innerHTML = "&#128172;";
    document.body.appendChild(launcher);

    panel = document.createElement("div");
    panel.className = "fp-chat-panel";
    panel.hidden = true;
    panel.innerHTML =
      '<div class="fp-chat-head">' +
        '<div><h4>Assistant</h4><div class="fp-chat-head-sub">Counsellor Q&amp;A &middot; powered by Groq</div></div>' +
        '<button type="button" class="fp-chat-close" aria-label="Close">&times;</button>' +
      '</div>' +
      '<div class="fp-chat-context-chip" id="fp-chat-context-chip" hidden></div>' +
      '<div class="fp-chat-messages" id="fp-chat-messages"></div>' +
      '<div class="fp-chat-input-row">' +
        '<input type="text" id="fp-chat-input" placeholder="Ask a question\u2026" autocomplete="off">' +
        '<button type="button" class="btn-primary" id="fp-chat-send">Send</button>' +
      '</div>';
    document.body.appendChild(panel);

    messagesEl = document.getElementById("fp-chat-messages");
    inputEl = document.getElementById("fp-chat-input");
    sendBtn = document.getElementById("fp-chat-send");
    contextChipEl = document.getElementById("fp-chat-context-chip");

    launcher.addEventListener("click", function(){ open(); });
    panel.querySelector(".fp-chat-close").addEventListener("click", close);
    sendBtn.addEventListener("click", send);
    inputEl.addEventListener("keydown", function(e){
      if(e.key === "Enter" && !sending) send();
    });

    addAssistantMessage("Hi! Ask me about a student's preferences (open their detail view and use \u201cAsk assistant\u201d), or a general question about merit formulas / how the site works.");
  }

  function open(){
    panel.hidden = false;
    inputEl.focus();
  }
  function close(){
    panel.hidden = true;
  }

  function setContext(studentId, studentName){
    activeStudentId = studentId;
    activeStudentName = studentName;
    if(studentId){
      contextChipEl.hidden = false;
      contextChipEl.innerHTML = 'Discussing: ' + esc(studentName || "this student") +
        ' <button type="button" aria-label="Clear context">&times;</button>';
      contextChipEl.querySelector("button").addEventListener("click", function(){ setContext(null, null); });
    } else {
      contextChipEl.hidden = true;
      contextChipEl.innerHTML = "";
    }
  }

  function addMessage(role, text){
    var div = document.createElement("div");
    div.className = "fp-chat-msg " + role;
    div.textContent = text;
    messagesEl.appendChild(div);
    messagesEl.scrollTop = messagesEl.scrollHeight;
    return div;
  }
  function addAssistantMessage(text){ return addMessage("assistant", text); }

  function send(){
    var message = inputEl.value.trim();
    if(!message || sending) return;

    addMessage("user", message);
    inputEl.value = "";
    sending = true;
    sendBtn.disabled = true;

    var pending = addMessage("pending", "Thinking\u2026");

    FP.client.functions.invoke(FUNCTION_NAME, {
      body: { message: message, studentId: activeStudentId }
    }).then(function(res){
      pending.remove();
      if(res.error){
        // On a non-2xx response, supabase-js leaves res.data null and
        // puts the raw Response on res.error.context -- our actual
        // { error: "..." } JSON body has to be parsed out of that
        // separately, it isn't just sitting on res.error.message.
        if(res.error.context && typeof res.error.context.json === "function"){
          res.error.context.json().then(function(body){
            addMessage("error", (body && body.error) || "Something went wrong. Try again.");
          }).catch(function(){
            addMessage("error", "Something went wrong. Try again.");
          });
        } else {
          addMessage("error", res.error.message || "Something went wrong. Try again.");
        }
        return;
      }
      var reply = (res.data && res.data.reply) || "Sorry, I couldn't generate a response.";
      addAssistantMessage(reply);
    }).catch(function(err){
      pending.remove();
      console.error("Chat assistant error:", err);
      addMessage("error", "Couldn't reach the assistant. Check your connection and try again.");
    }).finally(function(){
      sending = false;
      sendBtn.disabled = false;
    });
  }

  // ---------------------------------------------------------
  // Public API -- called from fp-admin.js's student detail view to
  // open the widget already scoped to a specific student.
  // ---------------------------------------------------------
  window.FP = window.FP || {};
  FP.chatAssistant = {
    openForStudent: function(studentId, studentName){
      if(!panel) buildWidget();
      setContext(studentId, studentName);
      open();
    }
  };

  // Only mount the launcher for counsellor/admin -- mirrors the
  // server-side check in the edge function, which is the real
  // enforcement point. This just avoids showing UI a student would
  // get a 403 from anyway.
  function init(){
    if(!window.FP || !FP.getSessionAndProfile) return;
    FP.getSessionAndProfile().then(function(result){
      if(!result) return;
      var role = result.profile ? result.profile.role : "student";
      if(role === "counsellor" || role === "admin"){
        buildWidget();
      }
    });
  }

  if(document.readyState === "loading"){
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
