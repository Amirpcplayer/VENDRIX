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
local pendingRequests = {}
local COMPLETION_EVENT = "onVendrixDatabaseQueryComplete"

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

local function isTrustedCaller(callerResource)
    if callerResource == nil or callerResource == false then
        return false, "unavailable"
    end

    -- sourceResource is a resource handle, not a player/game element.
    -- Resolve its name directly and fail closed if MTA rejects the handle.
    local ok, callerName = pcall(getResourceName, callerResource)
    if not ok or type(callerName) ~= "string" then
        return false, "invalid-resource-handle"
    end

    return TRUSTED_CALLERS[callerName] == true, callerName
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

local function dispatchResult(pending, ...)
    if not pending or not pending.callerRoot then
        return
    end

    if not isElement(pending.callerRoot)
        or getElementType(pending.callerRoot) ~= "resource" then
        return
    end

    triggerEvent(COMPLETION_EVENT, pending.callerRoot, pending.requestId, ...)
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
    local pending = pendingRequests[queryId]
    pendingRequests[queryId] = nil

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

        dispatchResult(
            pending,
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
        dispatchResult(pending, false, nil, nil, -1, "Query result was not ready.")
        log("ERROR", "MTA returned an unfinished query from its completion callback.")
        return
    end

    dispatchResult(
        pending,
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
    -- Capture the hidden export context before entering any helper function.
    local callerResource = sourceResource
    local trusted, callerName = isTrustedCaller(callerResource)
    local connectionValid = connection ~= nil and isElement(connection)

    log("DEBUG", ("isReady called; caller=%s; trusted=%s; ready=%s; connectionValid=%s."):format(
        tostring(callerName),
        tostring(trusted),
        tostring(ready),
        tostring(connectionValid)
    ))

    if not trusted then
        return false
    end

    return ready and connectionValid
end

function queryAsync(requestId, sql, ...)
    -- Exports cannot safely transfer Lua callback functions between resources.
    -- Capture the caller and return completion through a server-side resource event.
    local callerResource = sourceResource
    local trusted, callerName = isTrustedCaller(callerResource)
    if not trusted then
        log("WARN", ("queryAsync rejected caller=%s."):format(tostring(callerName)))
        return false
    end

    if not ready or not connection or not isElement(connection) then
        log("WARN", "queryAsync rejected request because the database is not ready.")
        return false
    end

    if type(requestId) ~= "number"
        or requestId < 1
        or requestId % 1 ~= 0
        or requestId > 2147483647 then
        log("WARN", "queryAsync rejected request because requestId is invalid.")
        return false
    end

    if type(sql) ~= "string" or sql == "" or #sql > 65535 then
        log("WARN", "queryAsync rejected request because SQL text is invalid.")
        return false
    end

    local callerRoot = getResourceRootElement(callerResource)
    if not callerRoot or not isElement(callerRoot) then
        log("WARN", ("queryAsync rejected request because caller root is unavailable (%s)."):format(
            tostring(callerName)
        ))
        return false
    end

    local parameterCount = select("#", ...)
    if parameterCount > 64 then
        log("WARN", "queryAsync rejected request because it has too many parameters.")
        return false
    end

    local parameters = {}
    for index = 1, parameterCount do
        local value = select(index, ...)
        if not isValidParameter(value) then
            log("WARN", ("queryAsync rejected unsupported parameter type at index %d."):format(index))
            return false
        end
        parameters[index] = value
    end

    repeat
        nextQueryId = nextQueryId + 1
    until pendingRequests[nextQueryId] == nil

    local queryId = nextQueryId
    pendingRequests[queryId] = {
        callerRoot = callerRoot,
        requestId = requestId
    }

    local ok, queryHandle = pcall(
        dbQuery,
        onQueryComplete,
        { queryId },
        connection,
        sql,
        unpack(parameters, 1, parameterCount)
    )

    if not ok then
        pendingRequests[queryId] = nil
        log("ERROR", ("dbQuery raised an error while queueing query: %s"):format(tostring(queryHandle)))
        return false
    end

    if not queryHandle then
        pendingRequests[queryId] = nil
        log("ERROR", "dbQuery returned no query handle; inspect the MTA database error log for the driver-level reason.")
        return false
    end

    log("DEBUG", ("queryAsync queued query id=%d request id=%d from caller=%s."):format(
        queryId,
        requestId,
        tostring(callerName)
    ))
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
    pendingRequests = {}
    destroyConnection()
    log("INFO", "Database connection closed.")
end)
