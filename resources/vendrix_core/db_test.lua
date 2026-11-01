-- Temporary VENDRIX database integration test.
-- Keep this file on the dedicated test branch; do not merge into production.
-- This test performs a read-only SELECT and does not modify database data.

local MAX_ATTEMPTS = 10
local RETRY_INTERVAL_MS = 500
local attempts = 0

local function runQueryTest()
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
                "[VENDRIX][TEST][FAIL] Database did not become ready after 5 seconds. Check database DEBUG logs for caller/trust/readiness state."
            )
        end
        return
    end

    outputServerLog("[VENDRIX][TEST] Sending asynchronous read-only SELECT query...")

    local queued = database:queryAsync(function(result, affectedRows, lastInsertId, errorCode)
        if type(result) ~= "table"
            or not result[1]
            or tonumber(result[1].query_ok) ~= 1 then
            outputServerLog(
                "[VENDRIX][TEST][FAIL] Query failed. Error code: "
                .. tostring(errorCode or "unknown")
            )
            return
        end

        outputServerLog(
            "[VENDRIX][TEST][SUCCESS] queryAsync returned the expected result."
        )
    end, "SELECT 1 AS query_ok")

    if not queued then
        outputServerLog(
            "[VENDRIX][TEST][FAIL] Query could not be queued although isReady returned true."
        )
    end
end

addEventHandler("onResourceStart", resourceRoot, function()
    attempts = 1
    setTimer(runQueryTest, RETRY_INTERVAL_MS, 1)
end)
