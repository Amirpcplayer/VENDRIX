local screenW, screenH = guiGetScreenSize()
local browserGUI
local browser
local browserReady = false
local uiOpen = true
local loginSound
local musicStarted = false
local CONFIG = VENDRIX_ACCOUNT_UI or {
    PAGE_URL = "http://mta/local/web/index.html",
    MUSIC_PATH = "assets/login_music.ogg",
    MUSIC_VOLUME = 0.30,
    ENABLE_BACKGROUND_MUSIC = true
}

local function sendToBrowser(eventName, success, code, rows)
    if not browserReady or not isElement(browser) then
        return
    end

    local payload = "window.VENDRIX && window.VENDRIX.receive("
        .. toJSON(eventName) .. ","
        .. (success and "true" or "false") .. ","
        .. toJSON(code or "") .. ","
        .. toJSON(rows or {}) .. ");"

    executeBrowserJavascript(browser, payload)
end

local function startMusic()
    if musicStarted or CONFIG.ENABLE_BACKGROUND_MUSIC ~= true then
        return
    end

    if not fileExists(CONFIG.MUSIC_PATH) then
        return
    end

    loginSound = playSound(CONFIG.MUSIC_PATH, true)
    if loginSound then
        setSoundVolume(loginSound, math.max(0, math.min(1, tonumber(CONFIG.MUSIC_VOLUME) or 0.30)))
        musicStarted = true
    end
end

local function stopMusic()
    if isElement(loginSound) then
        stopSound(loginSound)
    end
    loginSound = nil
    musicStarted = false
end

local function setUIVisible(visible)
    uiOpen = visible == true

    if isElement(browserGUI) then
        guiSetVisible(browserGUI, uiOpen)
    end

    showCursor(uiOpen)
    if uiOpen and browserReady then
        focusBrowser(browser)
    end
end

local function createNexusBrowser()
    browserGUI = guiCreateBrowser(0, 0, screenW, screenH, true, true, false)
    if not browserGUI then
        outputDebugString("[VENDRIX][ACCOUNTS] Failed to create CEF browser.", 1)
        return false
    end

    browser = guiGetBrowser(browserGUI)
    if not browser then
        destroyElement(browserGUI)
        browserGUI = nil
        outputDebugString("[VENDRIX][ACCOUNTS] Failed to obtain CEF browser handle.", 1)
        return false
    end

    addEventHandler("onClientBrowserCreated", browser, function()
        loadBrowserURL(source, CONFIG.PAGE_URL)
    end)

    addEventHandler("onClientBrowserDocumentReady", browser, function()
        browserReady = true
        setUIVisible(uiOpen)
        executeBrowserJavascript(browser, "document.documentElement.dataset.game='mta';")
        outputDebugString("[VENDRIX][ACCOUNTS] Nexus CEF interface is ready.", 3)
    end)

    addEventHandler("onClientBrowserLoadingFailed", browser, function(url, errorCode, errorDescription)
        outputDebugString(("[VENDRIX][ACCOUNTS] CEF load failed (%s): %s"):format(
            tostring(errorCode), tostring(errorDescription or url)
        ), 1)
    end)

    guiSetVisible(browserGUI, true)
    showCursor(true)
    return true
end

local function handleBrowserAction(action, data)
    if type(action) ~= "string" or type(data) ~= "table" then
        return
    end

    if action == "register" or action == "login" then
        local username = type(data.username) == "string" and data.username or ""
        local password = type(data.password) == "string" and data.password or ""
        if #username > 20 or #password > 72 then
            sendToBrowser(action .. "Result", false, "invalid_credentials")
            return
        end

        local eventName = action == "register"
            and "vendrix:accounts:register"
            or "vendrix:accounts:login"

        triggerServerEvent(eventName, localPlayer, username, password)
        return
    end

    if action == "changePassword" then
        local currentPassword = type(data.currentPassword) == "string" and data.currentPassword or ""
        local newPassword = type(data.newPassword) == "string" and data.newPassword or ""
        if #currentPassword > 72 or #newPassword > 72 then
            sendToBrowser("passwordResult", false, "invalid_password")
            return
        end

        triggerServerEvent(
            "vendrix:accounts:changePassword",
            localPlayer,
            currentPassword,
            newPassword
        )
        return
    end

    if action == "history" then
        triggerServerEvent("vendrix:accounts:requestHistory", localPlayer)
        return
    end

    if action == "logout" then
        triggerServerEvent("vendrix:accounts:logout", localPlayer)
    end
end

addEvent("vendrix:accounts:cefAction", true)
addEventHandler("vendrix:accounts:cefAction", root, function(action, data)
    startMusic()
    handleBrowserAction(action, data)
end)

addEvent("vendrix:accounts:cefInteraction", true)
addEventHandler("vendrix:accounts:cefInteraction", root, startMusic)

addEvent("vendrix:accounts:registerResult", true)
addEventHandler("vendrix:accounts:registerResult", resourceRoot, function(success, code)
    sendToBrowser("registerResult", success == true, code)
end)

addEvent("vendrix:accounts:loginResult", true)
addEventHandler("vendrix:accounts:loginResult", resourceRoot, function(success, code)
    sendToBrowser("loginResult", success == true, code)
    if success then
        stopMusic()
    end
end)

addEvent("vendrix:accounts:passwordResult", true)
addEventHandler("vendrix:accounts:passwordResult", resourceRoot, function(success, code)
    sendToBrowser("passwordResult", success == true, code)
end)

addEvent("vendrix:accounts:logoutResult", true)
addEventHandler("vendrix:accounts:logoutResult", resourceRoot, function(success, code)
    sendToBrowser("logoutResult", success == true, code)
    if success then
        startMusic()
    end
end)

addEvent("vendrix:accounts:history", true)
addEventHandler("vendrix:accounts:history", resourceRoot, function(rows, errorCode)
    if type(rows) ~= "table" then
        sendToBrowser("history", false, errorCode or "history_unavailable", {})
        return
    end

    sendToBrowser("history", true, "", rows)
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    createNexusBrowser()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    stopMusic()
    showCursor(false)
    if isElement(browserGUI) then
        destroyElement(browserGUI)
    end
    browserGUI = nil
    browser = nil
    browserReady = false
end)
