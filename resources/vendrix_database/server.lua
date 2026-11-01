-- VENDRIX database boundary.
-- Server-side only. Never expose the connection element to other resources.
-- SQL values must use MTA's ? placeholders; SQL identifiers must remain static.

local RESOURCE_NAME = getResourceName(getThisResource())
local TRUSTED_CALLERS = {
    vendrix_core = true
}

local connection = nil
local ready = false
local nextQueryId = 0
local pendingCallbacks = {}

local function log(level, message)
    outputServerLog(("[VENDRIX][%s][database] %s"):format(level, message))
end

local function getSetting(name)
    local value = get(RESOURCE_NAME .. "." .. name)
    if value == false or value == nil then
        return ""
    end

    return tostring(value)
end

local function isTrustedCaller()
    -- MTA supplies sourceResource for calls made through resource exports.
    if not sourceResource or not isElement(sourceResource) then
        return false
    end

    local callerName = getResourceName(sourceResource)
    return type(callerName) == "string" and TRUSTED_CALLERS[callerName] == true
end

local function isValidHost(value)
    return type(value) == "string"
        and value ~= ""
        and value:match("^[%w%.:%-]+$") ~= nil
end

local function isValidDatabaseName(value)
    return type(value) == "string"
        and value ~= ""
        and value:match("^[%w_%-]+$") ~= nil
end

local function destroyConnection()
    ready = false

    if connection and isElement(connection) then
        destroyElement(connection)
    end

    connection = nil
end

local function invokeCallback(callback, ...)
    local ok = pcall(callback, ...)
    if not ok then
        log("ERROR", "A resource query callback raised an error.")
    end
end

local function onInitialConnectionCheck(queryHandle)
    local rows, errorCode = dbPoll(queryHandle, 0)

    if type(rows) ~= "table"
        or not rows[1]
        or tonumber(rows[1].connection_ok) ~= 1 then
        log("ERROR", ("Database connection check failed (code %s)."):format(
            tostring(errorCode or "unknown")
        ))
        destroyConnection()
        return
    end

    ready = true
    log("INFO", "MariaDB connection established and verified.")
end

local function onQueryComplete(queryHandle, queryId)
    local pending = pendingCallbacks[queryId]
    pendingCallbacks[queryId] = nil

    if not pending then
        return
    end

    local result, affectedRows, lastInsertId = dbPoll(queryHandle, 0)

    if result == false then
        local errorCode = affectedRows
        local errorMessage = lastInsertId

        if errorCode == 2006 or errorCode == 2013 or errorCode == 2055 then
            ready = false
            log("WARN", "Database connection was lost. Restart vendrix_database after restoring MariaDB.")
        end

        invokeCallback(
            pending.callback,
            false,
            nil,
            nil,
            errorCode,
            errorMessage
        )
        return
    end

    if result == nil then
        dbFree(queryHandle)
        invokeCallback(pending.callback, false, nil, nil, -1, "Query result was not ready.")
        log("ERROR", "MTA returned an unfinished query from its completion callback.")
        return
    end

    invokeCallback(
        pending.callback,
        result,
        affectedRows,
        lastInsertId,
        nil,
        nil
    )
end

local function isValidParameter(value)
    local valueType = type(value)

    if valueType == "string" then
        return true
    end

    if valueType == "number" then
        return value == value and value ~= math.huge and value ~= -math.huge
    end

    return false
end

function isReady()
    if not isTrustedCaller() then
        return false
    end

    return ready and connection ~= nil and isElement(connection)
end

function queryAsync(callback, sql, ...)
    if not isTrustedCaller() then
        return false
    end

    if not ready or not connection or not isElement(connection) then
        return false
    end

    if type(callback) ~= "function"
        or type(sql) ~= "string"
        or sql == ""
        or #sql > 65535 then
        return false
    end

    local parameterCount = select("#", ...)
    if parameterCount > 64 then
        return false
    end

    local parameters = {}
    for index = 1, parameterCount do
        local value = select(index, ...)
        if not isValidParameter(value) then
            return false
        end
        parameters[index] = value
    end

    repeat
        nextQueryId = nextQueryId + 1
    until pendingCallbacks[nextQueryId] == nil

    local queryId = nextQueryId
    pendingCallbacks[queryId] = {
        callback = callback
    }

    local ok, queryHandle = pcall(
        dbQuery,
        onQueryComplete,
        { queryId },
        connection,
        sql,
        unpack(parameters, 1, parameterCount)
    )

    if not ok or not queryHandle then
        pendingCallbacks[queryId] = nil
        log("ERROR", "MTA could not queue a database query.")
        return false
    end

    return true
end

addEventHandler("onResourceStart", resourceRoot, function()
    ready = false

    local host = getSetting("db_host")
    local port = tonumber(getSetting("db_port"))
    local databaseName = getSetting("db_name")
    local username = getSetting("db_user")
    local password = getSetting("db_password")

    if not isValidHost(host)
        or not port
        or port < 1
        or port > 65535
        or port % 1 ~= 0
        or not isValidDatabaseName(databaseName)
        or username == ""
        or password == "" then
        log("WARN", "Database settings are incomplete or invalid; connection remains disabled.")
        return
    end

    local connectionString = ("dbname=%s;host=%s;port=%d;charset=utf8mb4"):format(
        databaseName,
        host,
        port
    )

    connection = dbConnect(
        "mysql",
        connectionString,
        username,
        password,
        "share=0;autoreconnect=0;batch=1;tag=vendrix_database;log=0"
    )

    if not connection or not isElement(connection) then
        connection = nil
        log("ERROR", "MTA could not create the MariaDB connection.")
        return
    end

    local queryHandle = dbQuery(
        onInitialConnectionCheck,
        connection,
        "SELECT 1 AS connection_ok"
    )

    if not queryHandle then
        log("ERROR", "MTA could not queue the initial database connection check.")
        destroyConnection()
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    pendingCallbacks = {}
    destroyConnection()
    log("INFO", "Database connection closed.")
end)
