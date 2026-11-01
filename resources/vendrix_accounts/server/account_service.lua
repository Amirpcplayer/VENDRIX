local pending = {}
local nextRequestId = 1000000
local requestRates = {}
local busyPlayers = {}

local function isPlayer(player)
    return isElement(player) and getElementType(player) == "player"
end

local function allocateRequestId()
    nextRequestId = nextRequestId + 1
    if nextRequestId > 1400000000 then
        nextRequestId = 1000001
    end
    return nextRequestId
end

local function canRequest(player)
    local now = getTickCount()
    local state = requestRates[player]

    if not state or now - state.windowStart >= VENDRIX_ACCOUNTS.RATE_WINDOW_MS then
        state = { windowStart = now, count = 0, lastRequest = now - VENDRIX_ACCOUNTS.REQUEST_COOLDOWN_MS }
        requestRates[player] = state
    end

    if now - state.lastRequest < VENDRIX_ACCOUNTS.REQUEST_COOLDOWN_MS
        or state.count >= VENDRIX_ACCOUNTS.MAX_REQUESTS_PER_WINDOW then
        return false
    end

    state.lastRequest = now
    state.count = state.count + 1
    return true
end

local function sendResult(player, eventName, success, code)
    if isPlayer(player) then
        triggerClientEvent(player, eventName, resourceRoot, success == true, code)
    end
end

local function validUsername(username)
    if type(username) ~= "string" then
        return false
    end

    local length = #username
    if length < VENDRIX_ACCOUNTS.USERNAME_MIN_LENGTH
        or length > VENDRIX_ACCOUNTS.USERNAME_MAX_LENGTH then
        return false
    end

    return username:match("^[A-Za-z0-9_]+$") ~= nil
end

local function validPassword(password)
    if type(password) ~= "string" then
        return false
    end

    if #password > VENDRIX_ACCOUNTS.PASSWORD_MAX_BYTES then
        return false
    end

    local characterLength = utfLen(password)
    return type(characterLength) == "number"
        and characterLength >= VENDRIX_ACCOUNTS.PASSWORD_MIN_LENGTH
end

function VENDRIX_ACCOUNTS_beginAction(player)
    if not isPlayer(player) or busyPlayers[player] then
        return false
    end

    busyPlayers[player] = true
    return true
end

function VENDRIX_ACCOUNTS_endAction(player)
    if player then
        busyPlayers[player] = nil
    end
end

function VENDRIX_ACCOUNTS_queueRequest(player, action, metadata, sql, ...)
    if not isPlayer(player) then
        return false
    end

    local requestId
    repeat
        requestId = allocateRequestId()
    until pending[requestId] == nil
    local item = metadata or {}
    item.player = player
    item.action = action
    pending[requestId] = item

    local queued = exports.vendrix_database:queryAsync(requestId, sql, ...)
    if not queued then
        pending[requestId] = nil
        return false
    end

    return requestId
end

function VENDRIX_ACCOUNTS_getPending(requestId)
    local item = pending[requestId]
    pending[requestId] = nil
    return item
end

function VENDRIX_ACCOUNTS_sendResult(player, eventName, success, code)
    sendResult(player, eventName, success, code)
end

function VENDRIX_ACCOUNTS_validUsername(username)
    return validUsername(username)
end

function VENDRIX_ACCOUNTS_validPassword(password)
    return validPassword(password)
end

function VENDRIX_ACCOUNTS_canRequest(player)
    return isPlayer(player) and canRequest(player)
end

addEventHandler("onPlayerQuit", root, function()
    requestRates[source] = nil
    busyPlayers[source] = nil

    for requestId, item in pairs(pending) do
        if item.player == source then
            pending[requestId] = nil
        end
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    pending = {}
    requestRates = {}
    busyPlayers = {}
end)
