(function () {
  "use strict";
  const $ = (id) => document.getElementById(id);
  const state = { mode: "login", busy: false };
  const messages = {
    registered: ["Hesab ba movafaghiyat sakhte shod. Hala vorood konid.", "success"],
    username_taken: ["In username ghablan sabt shode ast.", "error"],
    invalid_username: ["Username bayad 3 ta 20 karakter English va adad ya underscore bashad.", "error"],
    invalid_password: ["Ramz bayad hadaghal 10 karakter va bishtar az 72 byte nabashad.", "error"],
    hash_failed: ["Amniat sazi ramz anjam nashod. Dobare talash konid.", "error"],
    register_failed: ["Sakht hesab anjam nashod.", "error"],
    database_unavailable: ["Ertebat database dar dastres nist.", "error"],
    invalid_credentials: ["Username ya ramz eshtebah ast.", "error"],
    account_in_use: ["In hesab rooye yek vasl-e digar faal ast.", "error"],
    login_failed: ["Vorood anjam nashod.", "error"],
    logged_in: ["Vorood movafagh.", "success"],
    already_authenticated: ["Shoma ghablan vared shodeid.", "error"],
    password_changed: ["Ramz ba movafaghiyat taghir kard.", "success"],
    current_password_wrong: ["Ramz-e feli eshtebah ast.", "error"],
    password_change_failed: ["Taghir ramz anjam nashod.", "error"],
    password_update_failed: ["Zakhire ramz jadid anjam nashod.", "error"],
    logged_out: ["Az hesab kharej shodid.", "success"],
    history_unavailable: ["Tarikhche vorood dar dastres nist.", "error"]
  };
  let audioUnlockSent = false;\n  document.addEventListener("pointerdown", function () {\n    if (audioUnlockSent || !window.mta || typeof window.mta.triggerEvent !== "function") return;\n    audioUnlockSent = true;\n    window.mta.triggerEvent("vendrix:accounts:cefInteraction");\n  }, { once: true });\n  function bridge(action, data) {
    if (state.busy) return;
    if (window.mta && typeof window.mta.triggerEvent === "function") {
      state.busy = true;
      window.mta.triggerEvent("vendrix:accounts:cefAction", action, data || {});
    } else {
      setStatus("Ertebat ba game dar dastres nist.", "error");
    }
  }
  function setStatus(message, kind) {
    const node = $("status");
    node.textContent = message;
    node.className = "status " + (kind || "");
  }
  function showMode(mode) {
    state.mode = mode;
    $("authForm").classList.toggle("hidden", mode !== "login" && mode !== "register");
    $("authTabs").classList.toggle("hidden", mode !== "login" && mode !== "register");
    $("dashboard").classList.toggle("hidden", mode !== "dashboard");
    $("passwordPanel").classList.toggle("hidden", mode !== "password");
    $("historyPanel").classList.toggle("hidden", mode !== "history");
    $("confirmWrap").classList.toggle("hidden", mode !== "register");
    $("title").textContent = mode === "register" ? "Create your identity" : mode === "login" ? "Welcome back" : mode === "dashboard" ? "Identity verified" : mode === "password" ? "Change password" : "Login history";
    $("subtitle").textContent = mode === "register" ? "Create your VENDRIX account." : mode === "login" ? "Sign in to access your identity." : "Manage your NEXUS identity.";
    document.querySelectorAll(".tab").forEach(b => b.classList.toggle("active", b.dataset.mode === mode));
    if (mode === "login" || mode === "register") $("username").focus();
  }
  function clearPasswords() {
    ["password","confirm","currentPassword","newPassword","newConfirm"].forEach(id => { if ($(id)) $(id).value = ""; });
  }
  function setBusy(value) {
    state.busy = value;
    document.querySelectorAll("button").forEach(b => { b.disabled = value; });
  }
  document.querySelectorAll(".tab").forEach(b => b.addEventListener("click", () => {
    showMode(b.dataset.mode);
    setStatus(b.dataset.mode === "register" ? "Etelaate hesab jadid ra vared konid." : "Lotfan etelaate hesab ra vared konid.");
  }));
  $("authForm").addEventListener("submit", e => {
    e.preventDefault();
    if (state.busy) return;
    const username = $("username").value.trim();
    const password = $("password").value;
    if (state.mode === "register" && password !== $("confirm").value) {
      setStatus("Tekrar ramz ba ramz yeksan nist.", "error"); return;
    }
    const action = state.mode === "register" ? "register" : "login";
    setStatus(action === "login" ? "Dar hale barrasi etelaate hesab..." : "Dar hale sakht hesab...");
    clearPasswords(); setBusy(true);
    bridge(action, { username, password });
  });
  document.querySelectorAll(".action").forEach(b => b.addEventListener("click", () => {
    if (b.dataset.action === "password") showMode("password");
    else if (b.dataset.action === "history") { setStatus("Dar hale daryaft tarik..."); bridge("history"); }
    else if (b.dataset.action === "logout") bridge("logout");
  }));
  $("savePassword").addEventListener("click", () => {
    const currentPassword = $("currentPassword").value, newPassword = $("newPassword").value;
    if (newPassword !== $("newConfirm").value) { setStatus("Tekrar ramz jadid yeksan nist.", "error"); return; }
    clearPasswords(); setBusy(true); setStatus("Dar hale taghir ramz...");
    bridge("changePassword", { currentPassword, newPassword });
  });
  $("cancelPassword").addEventListener("click", () => showMode("dashboard"));
  $("backHistory").addEventListener("click", () => showMode("dashboard"));
  window.VENDRIX = {
    receive: function (eventName, success, code, rows) {
      setBusy(false);
      const msg = messages[code] || [success ? "Amaliat ba movafaghiyat anjam shod." : "Amaliat anjam nashod.", success ? "success" : "error"];
      setStatus(msg[0], msg[1]);
      if (eventName === "registerResult" && success) showMode("login");
      if (eventName === "loginResult" && success) showMode("dashboard");
      if (eventName === "passwordResult" && success) showMode("dashboard");
      if (eventName === "logoutResult" && success) { showMode("login"); clearPasswords(); }
      if (eventName === "history") {
        const list = $("historyList"); list.textContent = "";
        (Array.isArray(rows) ? rows : []).forEach(row => {
          const item = document.createElement("div"); item.className = "history-row";
          const outcome = document.createElement("span"); outcome.className = Number(row.result) === 1 ? "ok" : "fail";
          outcome.textContent = Number(row.result) === 1 ? "VOROOD MOVAFAGH" : "VOROOD NAMOVAFAGH";
          const date = document.createElement("time"); date.textContent = String(row.created_at || "");
          item.append(outcome, date); list.appendChild(item);
        });
        showMode("history");
      }
    },
    setStatus: setStatus,
    setBusy: setBusy
  };
  showMode("login");
})();