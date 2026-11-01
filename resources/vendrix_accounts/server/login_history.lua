local HISTORY_EVENT = "onVendrixAccountHistoryResult"
local nextHistoryRequestId = 1500000000
local historyRequests = {}

addEvent(HISTORY_EVENT, false)

local function allocateHistoryRequestId()
    nextHistoryRequestId = nextHistoryRequestId + 1
    if nextHistoryRequestId > 2000000000 then
        nextHistoryRequestId = 1500000001
    end
    return nextHistoryRequestId
end

function VENDRIX_ACCOUNTS_recordLogin(accountId, username, success, reason)
    if type(username) ~= "string" or #username < 1 or #username > 20 then
        return false
    end

    local requestId = allocateHistoryRequestId()
    local sql
    local queued

    if accountId then
        sql = [[
            INSERT INTO account_login_history
                (account_id, attempted_username, result, failure_reason, created_at)
            VALUES (?, ?, ?, ?, UTC_TIMESTAMP(3))
        ]]
        queued = exports.vendrix_database:queryAsync(
            requestId,
            sql,
            accountId,
            username,
            success and 1 or 0,
            success and "" or tostring(reason or "unknown")
        )
    else
        sql = [[
            INSERT INTO account_login_history
                (account_id, attempted_username, result, failure_reason, created_at)
            VALUES (NULL, ?, 0, ?, UTC_TIMESTAMP(3))
        ]]
        queued = exports.vendrix_database:queryAsync(
            requestId,
            sql,
            username,
            tostring(reason or "invalid_credentials")
        )
    end

    return queued == true
end

local function onHistoryQueryComplete(requestId, result, affectedRows, lastInsertId, errorCode, errorMessage)
    local player = historyRequests[requestId]
    historyRequests[requestId] = nil

    if not player or not isElement(player) or not isPlayerAuthenticated(player) then
        return
    end

    if type(result) ~= "table" then
        triggerClientEvent(player, "vendrix:accounts:history", resourceRoot, false, "history_unavailable")
        return
    end

    triggerClientEvent(player, "vendrix:accounts:history", resourceRoot, result)
end

addEventHandler("onVendrixDatabaseQueryComplete", resourceRoot, onHistoryQueryComplete)

addEvent("vendrix:accounts:requestHistory", true)
addEventHandler("vendrix:accounts:requestHistory", root, function()
    local player = client
    if not player or source ~= player or not isPlayerAuthenticated(player) then
        return
    end

    local accountId = getPlayerAccountId(player)
    local requestId = allocateHistoryRequestId()
    historyRequests[requestId] = player

    local queued = exports.vendrix_database:queryAsync(
        requestId,
        [[
            SELECT result, failure_reason, created_at
            FROM account_login_history
            WHERE account_id = ?
              AND created_at >= UTC_TIMESTAMP(3) - INTERVAL 90 DAY
            ORDER BY created_at DESC
            LIMIT 10
        ]],
        accountId
    )

    if not queued then
        historyRequests[requestId] = nil
        triggerClientEvent(player, "vendrix:accounts:history", resourceRoot, false, "history_unavailable")
    end
end)

local function cleanupExpiredHistory()
    local requestId = allocateHistoryRequestId()
    exports.vendrix_database:queryAsync(
        requestId,
        "DELETE FROM account_login_history WHERE created_at < UTC_TIMESTAMP(3) - INTERVAL 90 DAY"
    )
end

addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(
        cleanupExpiredHistory,
        10000,
        1
    )
    setTimer(
        cleanupExpiredHistory,
        VENDRIX_ACCOUNTS.LOGIN_HISTORY_CLEANUP_INTERVAL_MS,
        0
    )
end)

addEventHandler("onPlayerQuit", root, function()
    for requestId, player in pairs(historyRequests) do
        if player == source then
            historyRequests[requestId] = nil
        end
    end
end)
