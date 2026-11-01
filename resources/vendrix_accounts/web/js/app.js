(function () {
  "use strict";
  const $ = (id) => document.getElementById(id);
  const state = { mode: "login", busy: false };
  const messages = {
    registered: ["حساب شما با موفقیت ساخته شد. اکنون وارد شوید.", "success"],
    username_taken: ["این نام کاربری قبلاً ثبت شده است.", "error"],
    invalid_username: ["نام کاربری باید ۳ تا ۲۰ نویسه و شامل حروف انگلیسی، عدد یا زیرخط باشد.", "error"],
    invalid_password: ["رمز عبور باید حداقل ۱۰ نویسه و حداکثر ۷۲ بایت باشد.", "error"],
    hash_failed: ["ایمن‌سازی رمز عبور انجام نشد. دوباره تلاش کنید.", "error"],
    register_failed: ["ساخت حساب انجام نشد.", "error"],
    database_unavailable: ["پایگاه داده در دسترس نیست.", "error"],
    invalid_credentials: ["نام کاربری یا رمز عبور اشتباه است.", "error"],
    account_in_use: ["این حساب هم‌اکنون در اتصال دیگری فعال است.", "error"],
    login_failed: ["ورود به حساب انجام نشد.", "error"],
    logged_in: ["با موفقیت وارد حساب شدید.", "success"],
    already_authenticated: ["شما از قبل وارد حساب شده‌اید.", "error"],
    password_changed: ["رمز عبور با موفقیت تغییر کرد.", "success"],
    current_password_wrong: ["رمز عبور فعلی اشتباه است.", "error"],
    password_change_failed: ["تغییر رمز عبور انجام نشد.", "error"],
    password_update_failed: ["ذخیره رمز عبور جدید انجام نشد.", "error"],
    logged_out: ["با موفقیت از حساب خارج شدید.", "success"],
    history_unavailable: ["تاریخچه ورود در دسترس نیست.", "error"]
  };
  let audioUnlockSent = false;
  document.addEventListener("pointerdown", function () {
    if (audioUnlockSent || !window.mta || typeof window.mta.triggerEvent !== "function") return;
    audioUnlockSent = true;
    window.mta.triggerEvent("vendrix:accounts:cefInteraction");
  }, { once: true });
  function bridge(action, data) {
    if (window.mta && typeof window.mta.triggerEvent === "function") {
      state.busy = true;
      window.mta.triggerEvent("vendrix:accounts:cefAction", action, data || {});
    } else {
      setStatus("ارتباط با بازی در دسترس نیست.", "error");
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
    $("title").textContent = mode === "register" ? "ساخت حساب کاربری" : mode === "login" ? "خوش آمدی" : mode === "dashboard" ? "هویت شما تأیید شد" : mode === "password" ? "تغییر رمز عبور" : "تاریخچه ورود";
    $("subtitle").textContent = mode === "register" ? "حساب VENDRIX خود را بسازید." : mode === "login" ? "برای ورود به حساب، اطلاعات خود را وارد کنید." : "حساب NEXUS خود را مدیریت کنید.";
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
    setStatus(b.dataset.mode === "register" ? "اطلاعات حساب جدید را وارد کنید." : "لطفاً اطلاعات حساب خود را وارد کنید.");
  }));
  $("authForm").addEventListener("submit", e => {
    e.preventDefault();
    if (state.busy) return;
    const username = $("username").value.trim();
    const password = $("password").value;
    if (state.mode === "register" && password !== $("confirm").value) {
      setStatus("تکرار رمز عبور با رمز عبور یکسان نیست.", "error"); return;
    }
    const action = state.mode === "register" ? "register" : "login";
    setStatus(action === "login" ? "در حال بررسی اطلاعات حساب..." : "در حال ساخت حساب...");
    clearPasswords(); setBusy(true);
    bridge(action, { username, password });
  });
  document.querySelectorAll(".action").forEach(b => b.addEventListener("click", () => {
    if (b.dataset.action === "password") showMode("password");
    else if (b.dataset.action === "history") { setStatus("در حال دریافت تاریخچه..."); bridge("history"); }
    else if (b.dataset.action === "logout") bridge("logout");
  }));
  $("savePassword").addEventListener("click", () => {
    const currentPassword = $("currentPassword").value, newPassword = $("newPassword").value;
    if (newPassword !== $("newConfirm").value) { setStatus("تکرار رمز عبور جدید یکسان نیست.", "error"); return; }
    clearPasswords(); setBusy(true); setStatus("در حال تغییر رمز عبور...");
    bridge("changePassword", { currentPassword, newPassword });
  });
  $("cancelPassword").addEventListener("click", () => showMode("dashboard"));
  $("backHistory").addEventListener("click", () => showMode("dashboard"));
  window.VENDRIX = {
    receive: function (eventName, success, code, rows) {
      setBusy(false);
      const msg = messages[code] || [success ? "عملیات با موفقیت انجام شد." : "عملیات انجام نشد.", success ? "success" : "error"];
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
          outcome.textContent = Number(row.result) === 1 ? "ورود موفق" : "ورود ناموفق";
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
