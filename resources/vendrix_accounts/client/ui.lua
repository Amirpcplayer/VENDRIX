local screenW, screenH = guiGetScreenSize()
local panelW, panelH = 560, 520
local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2
local mode = "login"
local statusText = "Lotfan etelaate hesab ra vared konid."
local statusGood = false
local historyRows = {}
local controls = {}

local function destroyInputs()
    for _, element in pairs(controls) do
        if isElement(element) then
            destroyElement(element)
        end
    end
    controls = {}
end

local function createInput(key, caption, y, masked)
    dxDrawText(caption, panelX + 54, panelY + y - 22, panelX + panelW - 54, panelY + y - 2,
        tocolor(160, 190, 215, 255), 1, "default-bold", "left", "center")

    local edit = guiCreateEdit(panelX + 54, panelY + y, panelW - 108, 38, "", false)
    guiSetAlpha(edit, 0.94)
    guiSetProperty(edit, "NormalTextColour", "FFEAF7FF")
    guiSetProperty(edit, "NormalBGColour", "FF10243A")
    if masked then
        guiEditSetMasked(edit, true)
    end
    controls[key] = edit
end

local function setStatus(message, good)
    statusText = message
    statusGood = good == true
end

local messages = {
    registered = "Hesab ba movafaghiyat sakhte shod. Hala vorood konid.",
    username_taken = "In username ghablan sabt shode ast.",
    invalid_username = "Username bayad 3 ta 20 karakter English va adad ya underscore bashad.",
    invalid_password = "Ramz bayad hadaghal 10 karakter va bishtar az 72 byte nabashad.",
    hash_failed = "Amniat sazi ramz anjam nashod. Dobare talash konid.",
    register_failed = "Sakht hesab anjam nashod.",
    database_unavailable = "Ertebat database dar dastres nist.",
    invalid_credentials = "Username ya ramz eshtebah ast.",
    account_in_use = "In hesab rooye yek vasl-e digar faal ast.",
    login_failed = "Vorood anjam nashod.",
    logged_in = "Vorood movafagh.",
    already_authenticated = "Shoma ghablan vared shodeid.",
    password_changed = "Ramz ba movafaghiyat taghir kard.",
    current_password_wrong = "Ramz-e feli eshtebah ast.",
    password_change_failed = "Taghir ramz anjam nashod.",
    password_update_failed = "Zakhire ramz jadid anjam nashod.",
    invalid_password = "Ramz jadid motabar nist.",
    logged_out = "Az hesab kharej shodid."
}

local function displayCode(code, fallback)
    setStatus(messages[code] or fallback or "Amaliat anjam nashod.", code == "registered"
        or code == "logged_in" or code == "password_changed" or code == "logged_out")
end

local function drawButton(x, y, w, h, label, primary)
    local inside = isCursorShowing()
        and isMouseInPosition(x, y, w, h)
    local bg = primary and tocolor(0, inside and 150 or 125, inside and 235 or 205, 245)
        or tocolor(18, 42, 65, inside and 250 or 225)
    dxDrawRectangle(x, y, w, h, bg, true)
    dxDrawRectangle(x, y, w, 2, tocolor(55, 190, 255, 230), true)
    dxDrawText(label, x, y, x + w, y + h, tocolor(240, 249, 255, 255),
        1, "default-bold", "center", "center", false, false, true)
end

function isMouseInPosition(x, y, w, h)
    if not isCursorShowing() then
        return false
    end
    local cx, cy = getCursorPosition()
    if not cx or not cy then
        return false
    end
    cx, cy = cx * screenW, cy * screenH
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function renderPanel()
    dxDrawRectangle(0, 0, screenW, screenH, tocolor(3, 9, 18, 220), true)
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(7, 19, 33, 248), true)
    dxDrawRectangle(panelX, panelY, panelW, 3, tocolor(30, 174, 255, 255), true)
    dxDrawRectangle(panelX + 1, panelY + 1, panelW - 2, panelH - 2, tocolor(0, 0, 0, 0), true)

    dxDrawText("VENDRIX", panelX + 30, panelY + 24, panelX + panelW - 30, panelY + 70,
        tocolor(60, 190, 255, 255), 2.0, "default-bold", "center", "center")
    dxDrawText("NEXUS IDENTITY SYSTEM", panelX + 30, panelY + 70, panelX + panelW - 30, panelY + 94,
        tocolor(150, 185, 210, 255), 1, "default-bold", "center", "center")

    if mode == "login" or mode == "register" then
        dxDrawText(mode == "login" and "Khosh Amadi" or "Sakht Hesab", panelX + 54, panelY + 112,
            panelX + panelW - 54, panelY + 148, tocolor(240, 248, 255, 255),
            1.35, "default-bold", "left", "center")

        drawButton(panelX + 54, panelY + 160, 218, 34, "VOROOD", mode == "login")
        drawButton(panelX + 288, panelY + 160, 218, 34, "SABT NAM", mode == "register")

        dxDrawText("Vaziat: " .. statusText, panelX + 54, panelY + 425,
            panelX + panelW - 54, panelY + 465,
            statusGood and tocolor(80, 220, 180, 255) or tocolor(255, 175, 120, 255),
            1, "default", "left", "center", true)
        dxDrawText("VENDRIX NETWORK  |  NEXUS ID", panelX + 30, panelY + 486,
            panelX + panelW - 30, panelY + 510, tocolor(90, 125, 150, 255),
            0.85, "default", "center", "center")
    elseif mode == "dashboard" then
        dxDrawText("Hesab shoma amade ast", panelX + 54, panelY + 120,
            panelX + panelW - 54, panelY + 165, tocolor(230, 245, 255, 255),
            1.3, "default-bold", "center", "center")
        drawButton(panelX + 54, panelY + 205, 452, 42, "TAGHIR RAMZ", true)
        drawButton(panelX + 54, panelY + 260, 452, 42, "TARIKHCHE VOROOD", false)
        drawButton(panelX + 54, panelY + 315, 452, 42, "KHOROOJ AZ HESAB", false)
        dxDrawText(statusText, panelX + 54, panelY + 405, panelX + panelW - 54, panelY + 455,
            statusGood and tocolor(80, 220, 180, 255) or tocolor(255, 175, 120, 255),
            1, "default", "center", "center", true)
    elseif mode == "password" then
        dxDrawText("Taghir Ramz-e عبور", panelX + 54, panelY + 112,
            panelX + panelW - 54, panelY + 148, tocolor(240, 248, 255, 255),
            1.25, "default-bold", "left", "center")
        drawButton(panelX + 54, panelY + 430, 218, 38, "ZAKHIRE RAMZ", true)
        drawButton(panelX + 288, panelY + 430, 218, 38, "BAZگASHT", false)
        dxDrawText(statusText, panelX + 54, panelY + 475, panelX + panelW - 54, panelY + 505,
            statusGood and tocolor(80, 220, 180, 255) or tocolor(255, 175, 120, 255),
            0.9, "default", "left", "center", true)
    elseif mode == "history" then
        dxDrawText("Tarikچه Vorood", panelX + 54, panelY + 112,
            panelX + panelW - 54, panelY + 148, tocolor(240, 248, 255, 255),
            1.25, "default-bold", "left", "center")
        for index = 1, math.min(#historyRows, 10) do
            local row = historyRows[index]
            local label = tonumber(row.result) == 1 and "Movafagh" or "Namovafagh"
            local stamp = tostring(row.created_at or "")
            dxDrawText(label .. "  |  " .. stamp, panelX + 58, panelY + 160 + (index - 1) * 24,
                panelX + panelW - 58, panelY + 184 + (index - 1) * 24,
                tonumber(row.result) == 1 and tocolor(100, 220, 185, 255) or tocolor(245, 160, 125, 255),
                0.95, "default", "left", "center", true)
        end
        drawButton(panelX + 54, panelY + 430, 452, 38, "BAZگASHT", false)
    end
end

local function rebuildInputs()
    destroyInputs()
    if mode == "login" then
        createInput("username", "Nam-e Karbari", 220, false)
        createInput("password", "Ramz-e Obor", 285, true)
    elseif mode == "register" then
        createInput("username", "Nam-e Karbari (3 ta 20)", 220, false)
        createInput("password", "Ramz-e Obor (Min 10)", 285, true)
        createInput("confirm", "Tekrar Ramz-e Obor", 350, true)
    elseif mode == "password" then
        createInput("current", "Ramz-e Feli", 190, true)
        createInput("new", "Ramz-e Jadid", 255, true)
        createInput("confirm", "Tekrar Ramz-e Jadid", 320, true)
    end
end

local function openUI()
    showCursor(true)
    guiSetInputMode("no_binds_when_editing")
    rebuildInputs()
end

local function closeUI()
    destroyInputs()
    showCursor(false)
end

local function getValue(key)
    local element = controls[key]
    return isElement(element) and guiGetText(element) or ""
end

addEvent("vendrix:accounts:registerResult", true)
addEventHandler("vendrix:accounts:registerResult", resourceRoot, function(success, code)
    displayCode(code)
    if success then
        mode = "login"
        rebuildInputs()
    end
end)

addEvent("vendrix:accounts:loginResult", true)
addEventHandler("vendrix:accounts:loginResult", resourceRoot, function(success, code)
    displayCode(code)
    if success then
        mode = "dashboard"
        rebuildInputs()
    end
end)

addEvent("vendrix:accounts:passwordResult", true)
addEventHandler("vendrix:accounts:passwordResult", resourceRoot, function(success, code)
    displayCode(code)
    if success then
        mode = "dashboard"
        rebuildInputs()
    end
end)

addEvent("vendrix:accounts:logoutResult", true)
addEventHandler("vendrix:accounts:logoutResult", resourceRoot, function(success, code)
    displayCode(code)
    if success then
        mode = "login"
        setStatus("Lotfan dobare vorood konid.", false)
        rebuildInputs()
    end
end)

addEvent("vendrix:accounts:history", true)
addEventHandler("vendrix:accounts:history", resourceRoot, function(rows, errorCode)
    if type(rows) ~= "table" then
        historyRows = {}
        setStatus(messages[errorCode] or "Tarikچه vorood dar dastres nist.", false)
    else
        historyRows = rows
        setStatus("Tarikچه 90 rooze hesab shoma.", true)
    end
    mode = "history"
    rebuildInputs()
end)

addEventHandler("onClientRender", root, function()
    renderPanel()
end)

addEventHandler("onClientClick", root, function(button, state)
    if button ~= "left" or state ~= "down" then
        return
    end

    if mode == "login" or mode == "register" then
        if isMouseInPosition(panelX + 54, panelY + 160, 218, 34) then
            if mode ~= "login" then
                mode = "login"
                setStatus("Lotfan etelaate hesab ra vared konid.", false)
                rebuildInputs()
            else
                local username, password = getValue("username"), getValue("password")
                triggerServerEvent("vendrix:accounts:login", localPlayer, username, password)
                guiSetText(controls.password, "")
                setStatus("Dar hale barrasi etelaate hesab...", false)
            end
        elseif isMouseInPosition(panelX + 288, panelY + 160, 218, 34) then
            if mode ~= "register" then
                mode = "register"
                setStatus("Etelaate jadid ra vared konid.", false)
                rebuildInputs()
            else
                local username, password, confirm = getValue("username"), getValue("password"), getValue("confirm")
                if password ~= confirm then
                    setStatus("Tekrar ramz ba ramz yeksan nist.", false)
                    return
                end
                triggerServerEvent("vendrix:accounts:register", localPlayer, username, password)
                guiSetText(controls.password, "")
                guiSetText(controls.confirm, "")
                setStatus("Dar hale sakht hesab...", false)
            end
        end
    elseif mode == "dashboard" then
        if isMouseInPosition(panelX + 54, panelY + 205, 452, 42) then
            mode = "password"
            setStatus("Ramz-e feli va jadid ra vared konid.", false)
            rebuildInputs()
        elseif isMouseInPosition(panelX + 54, panelY + 260, 452, 42) then
            triggerServerEvent("vendrix:accounts:requestHistory", localPlayer)
            setStatus("Dar hale daryaft tarikچه...", false)
        elseif isMouseInPosition(panelX + 54, panelY + 315, 452, 42) then
            triggerServerEvent("vendrix:accounts:logout", localPlayer)
        end
    elseif mode == "password" then
        if isMouseInPosition(panelX + 54, panelY + 430, 218, 38) then
            local currentPassword = getValue("current")
            local newPassword = getValue("new")
            local confirm = getValue("confirm")
            if newPassword ~= confirm then
                setStatus("Tekrar ramz jadid yeksan nist.", false)
                return
            end
            triggerServerEvent("vendrix:accounts:changePassword", localPlayer, currentPassword, newPassword)
            guiSetText(controls.current, "")
            guiSetText(controls.new, "")
            guiSetText(controls.confirm, "")
            setStatus("Dar hale taghir ramz...", false)
        elseif isMouseInPosition(panelX + 288, panelY + 430, 218, 38) then
            mode = "dashboard"
            rebuildInputs()
        end
    elseif mode == "history" then
        if isMouseInPosition(panelX + 54, panelY + 430, 452, 38) then
            mode = "dashboard"
            rebuildInputs()
        end
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    openUI()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    closeUI()
end)
