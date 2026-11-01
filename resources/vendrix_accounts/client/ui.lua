local screenW, screenH = guiGetScreenSize()
local BASE_W, BASE_H = 760, 760
local scale = math.min(screenW / 1100, screenH / 900, 1)
local panelW, panelH = BASE_W * scale, BASE_H * scale
local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

local mode = "login"
local statusText = "Lotfan etelaate hesab ra vared konid."
local statusGood = false
local historyRows = {}
local controls = {}
local uiOpen = true

local C = {
    overlay = tocolor(8, 5, 22, 205),
    panel = tocolor(18, 12, 39, 246),
    panelInner = tocolor(23, 15, 48, 238),
    border = tocolor(170, 91, 255, 220),
    borderSoft = tocolor(104, 65, 166, 150),
    purple = tocolor(150, 35, 255, 255),
    purpleBright = tocolor(190, 65, 255, 255),
    text = tocolor(248, 243, 255, 255),
    muted = tocolor(190, 174, 216, 255),
    dim = tocolor(132, 115, 161, 255),
    success = tocolor(95, 225, 180, 255),
    error = tocolor(255, 155, 180, 255)
}

local function px(value)
    return value * scale
end

local function rect(x, y, w, h, color)
    dxDrawRectangle(x, y, w, h, color, false)
end

local function text(value, x, y, w, h, color, size, font, align)
    dxDrawText(value, x, y, x + w, y + h, color, size * scale,
        font or "default", align or "center", "center", true, false, false)
end

local function inside(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx or not cy then return false end
    cx, cy = cx * screenW, cy * screenH
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function box(x, y, w, h, fill, outline)
    rect(x, y, w, h, outline or C.borderSoft)
    rect(x + px(1), y + px(1), w - px(2), h - px(2), fill)
end

local function destroyInputs()
    for _, element in pairs(controls) do
        if isElement(element) then destroyElement(element) end
    end
    controls = {}
end

local function createInput(key, y, masked)
    local x = panelX + px(58)
    local w = panelW - px(116)
    local h = px(54)
    local edit = guiCreateEdit(x + px(2), panelY + px(y) + px(2), w - px(4), h - px(4), "", false)
    guiSetAlpha(edit, 0.98)
    guiSetProperty(edit, "NormalTextColour", "FFF7F0FF")
    guiSetProperty(edit, "NormalBGColour", "0017102D")
    guiSetProperty(edit, "HoverBGColour", "0017102D")
    guiSetProperty(edit, "ActiveBGColour", "0017102D")
    guiSetProperty(edit, "HoverTextColour", "FFFFFFFF")
    guiSetProperty(edit, "ActiveSelectionColour", "FF9635FF")
    if masked then guiEditSetMasked(edit, true) end
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
    setStatus(messages[code] or fallback or "Amaliat anjam nashod.",
        code == "registered" or code == "logged_in"
        or code == "password_changed" or code == "logged_out")
end

local function drawButton(x, y, w, h, label, primary, id)
    local hovered = inside(x, y, w, h)
    if primary then
        rect(x, y, w, h, hovered and tocolor(199, 72, 255, 255) or tocolor(133, 24, 224, 255))
        rect(x + px(2), y + px(2), w - px(4), h - px(4),
            hovered and tocolor(151, 37, 235, 255) or tocolor(111, 17, 202, 255))
        rect(x + px(3), y + h - px(4), w - px(6), px(2), tocolor(226, 142, 255, 180))
    else
        rect(x, y, w, h, hovered and tocolor(170, 94, 245, 255) or C.border)
        rect(x + px(2), y + px(2), w - px(4), h - px(4),
            hovered and tocolor(52, 31, 79, 255) or tocolor(23, 15, 43, 248))
    end
    text(label, x, y, w, h, C.text, 1.12, "default-bold")
end

local function drawFieldFrame(y, label)
    local x, w, h = panelX + px(58), panelW - px(116), px(58)
    box(x, panelY + px(y), w, h, tocolor(20, 14, 39, 250), C.borderSoft)
    text(label, x + px(70), panelY + px(y), w - px(88), h, C.dim, 1.02, "default")
    rect(x + px(22), panelY + px(y) + px(18), px(3), px(22), C.purpleBright)
end

local function drawBrand()
    local center = panelX + panelW / 2
    local top = panelY + px(28)
    -- Geometric V mark.
    dxDrawLine(center - px(54), top + px(8), center, top + px(72), tocolor(224, 190, 255, 255), px(8), false)
    dxDrawLine(center + px(54), top + px(8), center, top + px(72), tocolor(151, 65, 255, 255), px(8), false)
    dxDrawLine(center - px(48), top + px(8), center, top + px(63), tocolor(102, 32, 190, 255), px(2), false)
    dxDrawLine(center + px(48), top + px(8), center, top + px(63), tocolor(238, 202, 255, 255), px(2), false)
    text("VENDRIX", panelX + px(30), panelY + px(94), panelW - px(60), px(62), C.text, 2.7, "default-bold")
    text("R P G", panelX + px(30), panelY + px(150), panelW - px(60), px(32), C.muted, 1.45, "default-bold")
    rect(panelX + px(82), panelY + px(208), panelW - px(164), px(1), C.borderSoft)
    rect(panelX + px(82), panelY + px(207), px(112), px(3), C.purpleBright)
    rect(panelX + panelW - px(194), panelY + px(207), px(112), px(3), C.purpleBright)
    text("ACCOUNT SYSTEM", panelX + px(190), panelY + px(190), panelW - px(380), px(36),
        C.purpleBright, 1.15, "default-bold")
end

local function drawStatus(y)
    local color = statusGood and C.success or C.error
    text(statusText, panelX + px(48), panelY + px(y), panelW - px(96), px(34), color, 0.88, "default")
end

local function renderPanel()
    if not uiOpen then return end

    rect(0, 0, screenW, screenH, C.overlay)
    -- Subtle purple ambient glow behind the glass panel.
    rect(panelX - px(8), panelY - px(8), panelW + px(16), panelH + px(16), tocolor(94, 38, 150, 32))
    box(panelX, panelY, panelW, panelH, C.panel, C.border)
    rect(panelX + px(3), panelY + px(3), panelW - px(6), panelH - px(6), C.panelInner)
    rect(panelX + px(3), panelY + px(3), panelW - px(6), px(2), tocolor(225, 178, 255, 120))
    drawBrand()

    if mode == "login" or mode == "register" then
        local tabY, tabH = panelY + px(250), px(58)
        local tabW = (panelW - px(132)) / 2
        drawButton(panelX + px(58), tabY, tabW, tabH, "SABT NAM", false)
        drawButton(panelX + px(74) + tabW, tabY, tabW, tabH, "VOROOD BE HESAB", mode == "login")
        if mode == "register" then
            -- Active tab indication is deliberately restrained.
            rect(panelX + px(58), tabY + tabH - px(3), tabW, px(3), C.purpleBright)
        else
            rect(panelX + px(74) + tabW, tabY + tabH - px(3), tabW, px(3), C.purpleBright)
        end

        drawFieldFrame(330, "Nam-e karbari")
        drawFieldFrame(405, "Ramz-e oboor")
        if mode == "register" then drawFieldFrame(480, "Tekrar ramz-e oboor") end

        local actionY = mode == "register" and 560 or 495
        drawButton(panelX + px(58), panelY + px(actionY), panelW - px(116), px(60),
            mode == "login" and "VOROOD BE HESAB" or "SABT NAM DAR SERVER", true)
        rect(panelX + px(58), panelY + px(674), px(170), px(1), C.borderSoft)
        rect(panelX + panelW - px(228), panelY + px(674), px(170), px(1), C.borderSoft)
        text("YA", panelX + px(230), panelY + px(658), panelW - px(460), px(32), C.muted, 0.95)
        drawButton(panelX + px(58), panelY + px(690), panelW - px(116), px(48),
            mode == "login" and "SABT NAM DAR SERVER" or "BAZ GASHT BE VOROOD", false)
        drawStatus(625)
        text("VENDRIX NETWORK  |  NEXUS ID", panelX + px(30), panelY + px(735),
            panelW - px(60), px(20), C.dim, 0.72)
    elseif mode == "dashboard" then
        text("HESAB SHOMA AMADE AST", panelX + px(55), panelY + px(275),
            panelW - px(110), px(55), C.text, 1.35, "default-bold")
        drawButton(panelX + px(58), panelY + px(370), panelW - px(116), px(58), "TAGHIR RAMZ", true)
        drawButton(panelX + px(58), panelY + px(445), panelW - px(116), px(58), "TARIKHCHE VOROOD", false)
        drawButton(panelX + px(58), panelY + px(520), panelW - px(116), px(58), "KHOROOJ AZ HESAB", false)
        drawStatus(625)
        text("VENDRIX NETWORK  |  NEXUS ID", panelX + px(30), panelY + px(735),
            panelW - px(60), px(20), C.dim, 0.72)
    elseif mode == "password" then
        text("TAGHIR RAMZ-E OBOOR", panelX + px(55), panelY + px(270),
            panelW - px(110), px(45), C.text, 1.25, "default-bold")
        drawFieldFrame(350, "Ramz-e feli")
        drawFieldFrame(425, "Ramz-e jadid")
        drawFieldFrame(500, "Tekrar ramz-e jadid")
        drawButton(panelX + px(58), panelY + px(590), (panelW - px(132)) / 2, px(54), "ZAKHIRE RAMZ", true)
        drawButton(panelX + px(74) + (panelW - px(132)) / 2, panelY + px(590),
            (panelW - px(132)) / 2, px(54), "BAZGASHT", false)
        drawStatus(665)
    elseif mode == "history" then
        text("TARIKHCHE VOROOD", panelX + px(55), panelY + px(265),
            panelW - px(110), px(45), C.text, 1.25, "default-bold")
        for index = 1, math.min(#historyRows, 10) do
            local row = historyRows[index]
            local label = tonumber(row.result) == 1 and "VOROOD MOVAFAGH" or "VOROOD NAMOVAFAGH"
            local stamp = tostring(row.created_at or "")
            local y = panelY + px(330 + (index - 1) * 30)
            text(label .. "  |  " .. stamp, panelX + px(55), y, panelW - px(110), px(28),
                tonumber(row.result) == 1 and C.success or C.error, 0.88, "default", "left")
        end
        if #historyRows == 0 then
            text("HANOZ TARIKHCHE-I SABT NASHODE AST.", panelX + px(55), panelY + px(390),
                panelW - px(110), px(40), C.muted, 0.9)
        end
        drawButton(panelX + px(58), panelY + px(690), panelW - px(116), px(48), "BAZGASHT", false)
    end
end

local function rebuildInputs()
    destroyInputs()
    if mode == "login" then
        createInput("username", 332, false)
        createInput("password", 407, true)
    elseif mode == "register" then
        createInput("username", 332, false)
        createInput("password", 407, true)
        createInput("confirm", 482, true)
    elseif mode == "password" then
        createInput("current", 352, true)
        createInput("new", 427, true)
        createInput("confirm", 502, true)
    end
end

local function openUI()
    uiOpen = true
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

local function clearValue(key)
    local element = controls[key]
    if isElement(element) then guiSetText(element, "") end
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
        setStatus(messages[errorCode] or "Tarikhche vorood dar dastres nist.", false)
    else
        historyRows = rows
        setStatus("Tarikhche 90 rooze hesab shoma.", true)
    end
    mode = "history"
    rebuildInputs()
end)

addEventHandler("onClientRender", root, renderPanel)

addEventHandler("onClientClick", root, function(button, state)
    if not uiOpen or button ~= "left" or state ~= "down" then return end

    if mode == "login" or mode == "register" then
        local tabY = panelY + px(250)
        local tabW = (panelW - px(132)) / 2
        if inside(panelX + px(58), tabY, tabW, px(58)) then
            if mode ~= "register" then
                mode = "register"
                setStatus("Etelaate hesab jadid ra vared konid.", false)
                rebuildInputs()
            end
        elseif inside(panelX + px(74) + tabW, tabY, tabW, px(58)) then
            if mode ~= "login" then
                mode = "login"
                setStatus("Lotfan etelaate hesab ra vared konid.", false)
                rebuildInputs()
            end
        elseif mode == "login" and inside(panelX + px(58), panelY + px(495), panelW - px(116), px(60)) then
            local username, password = getValue("username"), getValue("password")
            triggerServerEvent("vendrix:accounts:login", localPlayer, username, password)
            clearValue("password")
            setStatus("Dar hale barrasi etelaate hesab...", false)
        elseif mode == "register" and inside(panelX + px(58), panelY + px(560), panelW - px(116), px(60)) then
            local username, password, confirm = getValue("username"), getValue("password"), getValue("confirm")
            if password ~= confirm then
                setStatus("Tekrar ramz ba ramz yeksan nist.", false)
                return
            end
            triggerServerEvent("vendrix:accounts:register", localPlayer, username, password)
            clearValue("password")
            clearValue("confirm")
            setStatus("Dar hale sakht hesab...", false)
        elseif inside(panelX + px(58), panelY + px(690), panelW - px(116), px(48)) then
            if mode == "login" then
                mode = "register"
                setStatus("Etelaate hesab jadid ra vared konid.", false)
            else
                mode = "login"
                setStatus("Lotfan etelaate hesab ra vared konid.", false)
            end
            rebuildInputs()
        end
    elseif mode == "dashboard" then
        if inside(panelX + px(58), panelY + px(370), panelW - px(116), px(58)) then
            mode = "password"
            setStatus("Ramz-e feli va jadid ra vared konid.", false)
            rebuildInputs()
        elseif inside(panelX + px(58), panelY + px(445), panelW - px(116), px(58)) then
            triggerServerEvent("vendrix:accounts:requestHistory", localPlayer)
            setStatus("Dar hale daryaft tarik...", false)
        elseif inside(panelX + px(58), panelY + px(520), panelW - px(116), px(58)) then
            triggerServerEvent("vendrix:accounts:logout", localPlayer)
        end
    elseif mode == "password" then
        local halfW = (panelW - px(132)) / 2
        if inside(panelX + px(58), panelY + px(590), halfW, px(54)) then
            local currentPassword = getValue("current")
            local newPassword = getValue("new")
            local confirm = getValue("confirm")
            if newPassword ~= confirm then
                setStatus("Tekrar ramz jadid yeksan nist.", false)
                return
            end
            triggerServerEvent("vendrix:accounts:changePassword", localPlayer, currentPassword, newPassword)
            clearValue("current")
            clearValue("new")
            clearValue("confirm")
            setStatus("Dar hale taghir ramz...", false)
        elseif inside(panelX + px(74) + halfW, panelY + px(590), halfW, px(54)) then
            mode = "dashboard"
            rebuildInputs()
        end
    elseif mode == "history" then
        if inside(panelX + px(58), panelY + px(690), panelW - px(116), px(48)) then
            mode = "dashboard"
            rebuildInputs()
        end
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, openUI)
addEventHandler("onClientResourceStop", resourceRoot, closeUI)
