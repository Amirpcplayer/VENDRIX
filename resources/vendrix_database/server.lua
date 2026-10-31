-- VENDRIX database boundary.
-- Intentionally does not connect automatically until the exact MTA build,
-- database backend support, and local credentials have been verified.

local RESOURCE_NAME = getResourceName(getThisResource())
local connection = nil
local isReady = false

local function log(level, message)
    outputServerLog(("[VENDRIX][%s][%s] %s"):format(level, RESOURCE_NAME, message))
end

local function setUnavailable(reason)
    isReady = false
    connection = nil
    log("WARN", "Database is not configured: " .. tostring(reason))
end

addEventHandler("onResourceStart", resourceRoot, function()
    setUnavailable("connection setup is intentionally disabled pending environment verification")
end)

addEventHandler("onResourceStop", resourceRoot, function()
    if connection and isElement(connection) then
        destroyElement(connection)
    end
    connection = nil
    isReady = false
end)

-- Exports intentionally omitted in this scaffold. Add a narrow, validated API
-- only after choosing and testing the connection/configuration strategy.
