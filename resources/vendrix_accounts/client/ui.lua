local screenW, screenH = guiGetScreenSize()
local BASE_W, BASE_H = 980, 730
local scale = math.min(screenW / 1440, screenH / 900, 1.15)
local panelW, panelH = BASE_W * scale, BASE_H * scale
local panelX, panelY = (screenW - panelW) / 2, (screenH - panelH) / 2

local mode = "login"
local statusText = "Lotfan etelaate hesab ra vared konid."
local statusGood = false
local historyRows = {}
local controls = {}
local uiOpen = true
local backgroundTexture
local loginSound
local musicStarted = false
local lastFrameTick = getTickCount()
local animationTime = 0

local CONFIG = VENDRIX_ACCOUNT_UI or {
    BACKGROUND_PATH = "assets/login_background.jpg",
    MUSIC_PATH = "assets/login_music.ogg",
    MUSIC_VOLUME = 0.35,
    ENABLE_BACKGROUND_MUSIC = true
}

local C = {
    shade = tocolor(2, 8, 19, 190),
    panel = tocolor(5, 17, 34, 232),
    panelDeep = tocolor(4, 13, 28, 244),
    glass = tocolor(13, 39, 62, 185),
    glassBright = tocolor(17, 62, 88, 170),
    cyan = tocolor(31, 220, 255, 255),
    blue = tocolor(25, 119, 255, 255),
    blueSoft = tocolor(30, 144, 210, 190),
    line = tocolor(49, 190, 225, 150),
    white = tocolor(235, 249, 255, 255),
    muted = tocolor(153, 190, 207, 255),
    dim = tocolor(101, 143, 165, 255),
    success = tocolor(93, 235, 180, 255),
    error = tocolor(255, 125, 143, 255)
}

local function px(v) return v * scale end

local function rect(x, y, w, h, color)
    dxDrawRectangle(x, y, w, h, color, false)
end

local function line(x1, y1, x2, y2, color, width)
    dxDrawLine(x1, y1, x2, y2, color, width or px(1), false)
end

local function drawText(value, x, y, w, h, color, size, font, align)
    dxDrawText(tostring(value or ""), x, y, x + w, y + h, color,
        size * scale, font or "default", align or "left", "center",
        true, false, false, false)
end

local function cursorInside(x, y, w, h)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    if not cx or not cy then return false end
    cx, cy = cx * screenW, cy * screenH
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function roundedPanel(x, y, w, h, fill, edge)
    -- Layered rectangles and corner cuts create a lightweight glass-card silhouette.
    rect(x + px(5), y + px(7), w, h, tocolor(0, 0, 0, 95))
    rect(x, y, w, h, edge or C.line)
    rect(x + px(1), y + px(1), w - px(2), h - px(2), fill)
    rect(x + px(8), y + px(8), w - px(16), px(1), tocolor(115, 235, 255, 65))
    rect(x + px(8), y + h - px(9), w - px(16), px(1), tocolor(35, 160, 220, 55))
    rect(x + px(8), y + px(8), px(2), h - px(16), tocolor(48, 204, 255, 75))
end

local function destroyInputs()
    for _, element in pairs(controls) do
        if isElement(element) then destroyElement(element) end
    end
    controls = {}
end

local function createInput(key, x, y, w, placeholder, masked)
    local edit = guiCreateEdit(x + px(2), y + px(2), w - px(4), px(48), "", false)
    if not edit then return end
    guiSetAlpha(edit, 0.98)
    guiSetProperty(edit, "NormalTextColour", "FFEAFBFF")
    guiSetProperty(edit, "NormalBGColour", "00102030")
    guiSetProperty(edit, "HoverBGColour", "00102030")
    guiSetProperty(edit, "ActiveBGColour", "00102030")
    guiSetProperty(edit, "ActiveSelectionColour", "FF20CFFF")
    guiSetProperty(edit, "CaretColour", "FF20CFFF")
    guiSetFont(edit, "default")
    guiSetText(edit, "")
    if masked then guiEditSetMasked(edit, true) end
    controls[key] = edit
end

local function fieldFrame(x, y, w, label)
    roundedPanel(x, y, w, px(52), tocolor(5, 20, 36, 225), tocolor(33, 157, 198, 145))
    rect(x + px(13), y + px(13), px(3), px(26), C.cyan)
    drawText(label, x + px(25), y + px(2), px(130), px(48), C.dim, 0.86)
end

local function button(x, y, w, h, label, primary)
    local hover = cursorInside(x, y, w, h)
    if primary then
        rect(x + px(3), y + px(5), w, h, tocolor(0, 0, 0, 105))
        rect(x, y, w, h, hover and tocolor(75, 231, 255, 255) or C.blue)
        rect(x + px(2), y + px(2), w - px(4), h - px(4),
            hover and tocolor(11, 111, 179, 255) or tocolor(8, 75, 145, 255))
        rect(x + px(5), y + px(4), w - px(10), px(2), tocolor(175, 250, 255, 165))
    else
        rect(x, y, w, h, hover and tocolor(50, 196, 225, 210) or tocolor(36, 117, 154, 170))
        rect(x + px(1), y + px(1), w - px(2), h - px(2),
            hover and tocolor(15, 66, 88, 245) or tocolor(7, 31, 49, 238))
    end
    drawText(label, x + px(8), y, w - px(16), h, C.white, 1.02, "default-bold", "center")
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
    logged_out = "Az hesab kharej shodid."
}

local function setStatus(message, good)
    statusText = message or "Amaliat anjam nashod."
    statusGood = good == true
end

local function displayCode(code, fallback)
    setStatus(messages[code] or fallback or "Amaliat anjam nashod.",
        code == "registered" or code == "logged_in"
        or code == "password_changed" or code == "logged_out")
end

local function startMusic()
    if musicStarted or CONFIG.ENABLE_BACKGROUND_MUSIC ~= true then return end
    if not fileExists(CONFIG.MUSIC_PATH) then return end
    loginSound = playSound(CONFIG.MUSIC_PATH, true)
    if loginSound then
        setSoundVolume(loginSound, math.max(0, math.min(1, tonumber(CONFIG.MUSIC_VOLUME) or 0.35)))
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

local function loadBackground()
    if isElement(backgroundTexture) then
        destroyElement(backgroundTexture)
    end
    backgroundTexture = nil
    if fileExists(CONFIG.BACKGROUND_PATH) then
        backgroundTexture = dxCreateTexture(CONFIG.BACKGROUND_PATH, "argb", true, "clamp")
    end
end

local function drawBackground()
    if isElement(backgroundTexture) then
        local tw, th = dxGetMaterialSize(backgroundTexture)
        if tw and th and tw > 0 and th > 0 then
            local screenRatio, imageRatio = screenW / screenH, tw / th
            local drawW, drawH = screenW, screenH
            if imageRatio > screenRatio then
                drawW = screenH * imageRatio
            else
                drawH = screenW / imageRatio
            end
            dxDrawImage((screenW - drawW) / 2, (screenH - drawH) / 2,
                drawW, drawH, backgroundTexture, 0, 0, 0, tocolor(255, 255, 255, 255), false)
        end
    else
        rect(0, 0, screenW, screenH, tocolor(4, 13, 27, 255))
        for i = 0, 12 do
            local x = (i / 12) * screenW
            line(x, 0, x - screenH * 0.35, screenH, tocolor(22, 117, 166, 24), px(1))
        end
        rect(0, screenH * 0.62, screenW, screenH * 0.38, tocolor(3, 26, 43, 90))
    end
    rect(0, 0, screenW, screenH, C.shade)
    rect(0, 0, screenW, px(2), tocolor(32, 199, 255, 100))
end

local function drawCornerBrackets(x, y, w, h)
    local l, c = px(34), C.cyan
    line(x, y + l, x, y, c, px(2)); line(x, y, x + l, y, c, px(2))
    line(x + w - l, y, x + w, y, c, px(2)); line(x + w, y, x + w, y + l, c, px(2))
    line(x, y + h - l, x, y + h, c, px(2)); line(x, y + h, x + l, y + h, c, px(2))
    line(x + w - l, y + h, x + w, y + h, c, px(2)); line(x + w, y + h - l, x + w, y + h, c, px(2))
end

local function drawBrand()
    local x, y = panelX + px(54), panelY + px(48)
    drawText("V", x, y, px(74), px(78), C.cyan, 4.2, "default-bold", "center")
    line(x + px(5), y + px(79), x + px(70), y + px(79), C.blue, px(3))
    drawText("VENDRIX", x + px(88), y + px(4), px(300), px(42), C.white, 2.0, "default-bold")
    drawText("N E X U S   I D   /   ACCOUNT ACCESS", x + px(90), y + px(43),
        px(410), px(28), C.muted, 0.78, "default-bold")
    drawText("SECURE NETWORK", panelX + panelW - px(250), panelY + px(57),
        px(190), px(25), C.cyan, 0.78, "default-bold", "right")
    drawText("IDENTITY GATEWAY  •  ONLINE", panelX + panelW - px(300), panelY + px(83),
        px(240), px(22), C.muted, 0.68, "default", "right")
end

local function drawStatus(x, y, w)
    local color = statusGood and C.success or C.error
    rect(x, y + px(2), px(3), px(24), color)
    drawText(statusText, x + px(12), y, w - px(12), px(28), color, 0.78)
end

local function drawLoginRegister()
    local contentX = panelX + px(500)
    local contentW = panelW - px(555)
    local tabY = panelY + px(190)
    local tabW = (contentW - px(12)) / 2
    button(contentX, tabY, tabW, px(48), "SABT NAM", mode == "register")
    button(contentX + tabW + px(12), tabY, tabW, px(48), "VOROOD", mode == "login")

    drawText(mode == "login" and "Welcome back" or "Create your identity",
        contentX, panelY + px(255), contentW, px(42), C.white, 1.55, "default-bold")
    drawText(mode == "login" and "Baraye edame be VENDRIX vared shavid."
        or "Hesab jadid khod ra besazid.",
        contentX, panelY + px(298), contentW, px(28), C.muted, 0.84)

    local fieldY = panelY + px(355)
    fieldFrame(contentX, fieldY, contentW, "USERNAME")
    fieldFrame(contentX, fieldY + px(72), contentW, "PASSWORD")
    if mode == "register" then
        fieldFrame(contentX, fieldY + px(144), contentW, "CONFIRM PASSWORD")
    end

    local actionY = mode == "login" and panelY + px(520) or panelY + px(592)
    button(contentX, actionY, contentW, px(54),
        mode == "login" and "VOROOD BE HESAB" or "SABT NAM DAR SERVER", true)
    if mode == "login" then
        button(contentX, panelY + px(590), contentW, px(42), "SABT NAM DAR SERVER", false)
    else
        button(contentX, panelY + px(660), contentW, px(42), "BAZ GASHT BE VOROOD", false)
    end
    drawStatus(contentX, panelY + px(322), contentW)
end

local function drawDashboard()
    local x, w = panelX + px(500), panelW - px(555)
    drawText("HESAB SHOMA AMADE AST", x, panelY + px(220), w, px(52),
        C.white, 1.4, "default-bold")
    drawText("Manage your NEXUS identity", x, panelY + px(270), w, px(30), C.muted, 0.85)
    button(x, panelY + px(350), w, px(54), "TAGHIR RAMZ", true)
    button(x, panelY + px(420), w, px(54), "TARIKHCHE VOROOD", false)
    button(x, panelY + px(490), w, px(54), "KHOROOJ AZ HESAB", false)
    drawStatus(x, panelY + px(590), w)
end

local function drawPassword()
    local x, w = panelX + px(500), panelW - px(555)
    drawText("TAGHIR RAMZ-E OBOOR", x, panelY + px(220), w, px(46), C.white, 1.3, "default-bold")
    fieldFrame(x, panelY + px(310), w, "CURRENT PASSWORD")
    fieldFrame(x, panelY + px(382), w, "NEW PASSWORD")
    fieldFrame(x, panelY + px(454), w, "CONFIRM PASSWORD")
    local half = (w - px(10)) / 2
    button(x, panelY + px(540), half, px(50), "ZAKHIRE RAMZ", true)
    button(x + half + px(10), panelY + px(540), half, px(50), "BAZGASHT", false)
    drawStatus(x, panelY + px(610), w)
end

local function drawHistory()
    local x, w = panelX + px(500), panelW - px(555)
    drawText("TARIKHCHE VOROOD", x, panelY + px(205), w, px(45), C.white, 1.25, "default-bold")
    for i = 1, math.min(#historyRows, 10) do
        local row = historyRows[i]
        local success = tonumber(row.result) == 1
        local label = success and "VOROOD MOVAFAGH" or "VOROOD NAMOVAFAGH"
        local stamp = tostring(row.created_at or "")
        local y = panelY + px(270 + (i - 1) * 31)
        rect(x, y + px(2), w, px(27), tocolor(8, 31, 48, 190))
        drawText(label, x + px(10), y, w * 0.48, px(30),
            success and C.success or C.error, 0.72, "default-bold")
        drawText(stamp, x + w * 0.48, y, w * 0.49, px(30), C.muted, 0.68, "default", "right")
    end
    if #historyRows == 0 then
        drawText("HANOZ TARIKHCHE-I SABT NASHODE AST.", x, panelY + px(350),
            w, px(36), C.muted, 0.8)
    end
    button(x, panelY + px(610), w, px(46), "BAZGASHT", false)
end

local function renderPanel()
    if not uiOpen then return end
    local now = getTickCount()
    local delta = math.min(now - lastFrameTick, 100)
    lastFrameTick = now
    animationTime = animationTime + delta
    drawBackground()

    -- Decorative ambient beams are deliberately low-cost and static.
    local beamX = panelX + px(30) + ((animationTime * 0.018) % (panelW - px(60)))
    rect(beamX, panelY + px(4), px(1), panelH - px(8), tocolor(38, 190, 255, 15))

    roundedPanel(panelX, panelY, panelW, panelH, C.panel, tocolor(37, 188, 230, 190))
    drawCornerBrackets(panelX, panelY, panelW, panelH)
    drawBrand()

    -- Left-side identity artwork area. The supplied background remains visible behind it.
    local leftX, leftY = panelX + px(54), panelY + px(190)
    drawText("YOUR WORLD.", leftX, leftY + px(72), px(370), px(55), C.white, 2.0, "default-bold")
    drawText("YOUR IDENTITY.", leftX, leftY + px(125), px(390), px(55), C.cyan, 1.65, "default-bold")
    rect(leftX, leftY + px(196), px(92), px(3), C.blue)
    drawText("One account. One world. Endless possibilities.",
        leftX, leftY + px(218), px(365), px(60), C.muted, 0.86)
    drawText("VENDRIX ROLEPLAY NETWORK", leftX, panelY + panelH - px(58),
        px(390), px(24), C.dim, 0.7, "default-bold")

    local rightX = panelX + px(465)
    rect(rightX, panelY + px(150), px(1), panelH - px(205), tocolor(49, 182, 220, 85))
    if mode == "login" or mode == "register" then
        drawLoginRegister()
    elseif mode == "dashboard" then
        drawDashboard()
    elseif mode == "password" then
        drawPassword()
    elseif mode == "history" then
        drawHistory()
    end
end

local function rebuildInputs()
    destroyInputs()
    local x = panelX + px(500)
    local w = panelW - px(555)
    local y = panelY + px(355)
    if mode == "login" or mode == "register" then
        createInput("username", x + px(130), y + px(1), w - px(135), "Username", false)
        createInput("password", x + px(130), y + px(73), w - px(135), "Password", true)
        if mode == "register" then
            createInput("confirm", x + px(130), y + px(145), w - px(135), "Confirm", true)
        end
    elseif mode == "password" then
        createInput("current", x + px(130), panelY + px(311), w - px(135), "Current", true)
        createInput("new", x + px(130), panelY + px(383), w - px(135), "New", true)
        createInput("confirm", x + px(130), panelY + px(455), w - px(135), "Confirm", true)
    end
end

local function openUI()
    uiOpen = true
    showCursor(true)
    guiSetInputMode("no_binds_when_editing")
    rebuildInputs()
    startMusic()
end

local function closeUI()
    uiOpen = false
    destroyInputs()
    stopMusic()
    if isElement(backgroundTexture) then destroyElement(backgroundTexture) end
    backgroundTexture = nil
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
        stopMusic()
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
        startMusic()
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

addEventHandler("onClientClick", root, function(mouseButton, state)
    if not uiOpen or mouseButton ~= "left" or state ~= "down" then return end
    local x, w = panelX + px(500), panelW - px(555)

    if mode == "login" or mode == "register" then
        local tabY = panelY + px(190)
        local tabW = (w - px(12)) / 2
        if cursorInside(x, tabY, tabW, px(48)) then
            mode = "register"
            setStatus("Etelaate hesab jadid ra vared konid.", false)
            rebuildInputs()
        elseif cursorInside(x + tabW + px(12), tabY, tabW, px(48)) then
            mode = "login"
            setStatus("Lotfan etelaate hesab ra vared konid.", false)
            rebuildInputs()
        elseif mode == "login" and cursorInside(x, panelY + px(520), w, px(54)) then
            triggerServerEvent("vendrix:accounts:login", localPlayer, getValue("username"), getValue("password"))
            clearValue("password")
            setStatus("Dar hale barrasi etelaate hesab...", false)
        elseif mode == "register" and cursorInside(x, panelY + px(592), w, px(54)) then
            local password, confirm = getValue("password"), getValue("confirm")
            if password ~= confirm then
                setStatus("Tekrar ramz ba ramz yeksan nist.", false)
                return
            end
            triggerServerEvent("vendrix:accounts:register", localPlayer, getValue("username"), password)
            clearValue("password")
            clearValue("confirm")
            setStatus("Dar hale sakht hesab...", false)
        elseif mode == "login" and cursorInside(x, panelY + px(590), w, px(42)) then
            mode = "register"
            setStatus("Etelaate hesab jadid ra vared konid.", false)
            rebuildInputs()
        elseif mode == "register" and cursorInside(x, panelY + px(660), w, px(42)) then
            mode = "login"
            setStatus("Lotfan etelaate hesab ra vared konid.", false)
            rebuildInputs()
        end
    elseif mode == "dashboard" then
        if cursorInside(x, panelY + px(350), w, px(54)) then
            mode = "password"
            setStatus("Ramz-e feli va jadid ra vared konid.", false)
            rebuildInputs()
        elseif cursorInside(x, panelY + px(420), w, px(54)) then
            triggerServerEvent("vendrix:accounts:requestHistory", localPlayer)
            setStatus("Dar hale daryaft tarik...", false)
        elseif cursorInside(x, panelY + px(490), w, px(54)) then
            triggerServerEvent("vendrix:accounts:logout", localPlayer)
        end
    elseif mode == "password" then
        local half = (w - px(10)) / 2
        if cursorInside(x, panelY + px(540), half, px(50)) then
            local currentPassword, newPassword, confirm = getValue("current"), getValue("new"), getValue("confirm")
            if newPassword ~= confirm then
                setStatus("Tekrar ramz jadid yeksan nist.", false)
                return
            end
            triggerServerEvent("vendrix:accounts:changePassword", localPlayer, currentPassword, newPassword)
            clearValue("current"); clearValue("new"); clearValue("confirm")
            setStatus("Dar hale taghir ramz...", false)
        elseif cursorInside(x + half + px(10), panelY + px(540), half, px(50)) then
            mode = "dashboard"
            rebuildInputs()
        end
    elseif mode == "history" and cursorInside(x, panelY + px(610), w, px(46)) then
        mode = "dashboard"
        rebuildInputs()
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    loadBackground()
    openUI()
end)

addEventHandler("onClientResourceStop", resourceRoot, closeUI)
