local pending = {}
local nextRequestId = 1000000
local lastRequestTick = {}

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
    local previous = lastRequestTick[player]

    if previous and now - previous < VENDRIX_ACCOUNTS.REQUEST_COOLDOWN_MS then
        return false
    end

    lastRequestTick[player] = now
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

    local characterLength = utfLen(password)
    return characterLength ~= false
        and characterLength >= VENDRIX_ACCOUNTS.PASSWORD_MIN_LENGTH
        and #password <= VENDRIX_ACCOUNTS.PASSWORD_MAX_BYTES
end

function VENDRIX_ACCOUNTS_queueRequest(player, action, metadata, sql, ...)
    if not isPlayer(player) then
        return false
    end

    local requestId = allocateRequestId()
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
    lastRequestTick[source] = nil

    for requestId, item in pairs(pending) do
        if item.player == source then
            pending[requestId] = nil
        end
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    pending = {}
    lastRequestTick = {}
end)
