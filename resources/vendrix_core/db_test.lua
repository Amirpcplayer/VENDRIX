-- Temporary VENDRIX database integration test.
-- Keep this file on the dedicated test branch; do not merge into production.
-- This test performs a read-only SELECT and does not modify database data.

local MAX_ATTEMPTS = 10
local RETRY_INTERVAL_MS = 500
local attempts = 0
local TEST_REQUEST_ID = 700001

addEvent("onVendrixDatabaseQueryComplete", false)

addEventHandler("onVendrixDatabaseQueryComplete", resourceRoot, function(
    requestId,
    result,
    affectedRows,
    lastInsertId,
    errorCode,
    errorMessage
)
    if requestId ~= TEST_REQUEST_ID then
        return
    end

    if type(result) ~= "table"
        or not result[1]
        or tonumber(result[1].query_ok) ~= 1 then
        outputServerLog(
            "[VENDRIX][TEST][FAIL] Query failed. Error code: "
            .. tostring(errorCode or "unknown")
            .. "; message: "
            .. tostring(errorMessage or "no details")
        )
        return
    end

    outputServerLog(
        "[VENDRIX][TEST][SUCCESS] Event-based queryAsync returned the expected result."
    )
end)

local function runQueryTest()
    attempts = attempts + 1
    local database = exports.vendrix_database

    outputServerLog(("[VENDRIX][TEST] Readiness check %d/%d..."):format(
        attempts,
        MAX_ATTEMPTS
    ))

    if not database:isReady() then
        if attempts < MAX_ATTEMPTS then
            setTimer(runQueryTest, RETRY_INTERVAL_MS, 1)
        else
            outputServerLog(
                "[VENDRIX][TEST][FAIL] Database did not become ready after 5 seconds."
            )
        end
        return
    end

    outputServerLog("[VENDRIX][TEST] Sending event-based asynchronous read-only SELECT query...")

    local queued = database:queryAsync(TEST_REQUEST_ID, "SELECT 1 AS query_ok")
    if not queued then
        outputServerLog(
            "[VENDRIX][TEST][FAIL] Event-based query could not be queued. Check database logs."
        )
        return
    end

    outputServerLog("[VENDRIX][TEST] Query queued; waiting for completion event...")
end

addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(runQueryTest, RETRY_INTERVAL_MS, 1)
end)
