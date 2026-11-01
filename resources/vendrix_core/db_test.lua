-- Temporary VENDRIX database integration test.
-- Keep this file on the dedicated test branch; do not merge into production.
-- This test performs a read-only SELECT and does not modify database data.

addEventHandler("onResourceStart", resourceRoot, function()
    local database = exports.vendrix_database

    if not database:isReady() then
        outputServerLog("[VENDRIX][TEST][FAIL] Database is not ready.")
        return
    end

    outputServerLog("[VENDRIX][TEST] Sending asynchronous SELECT query...")

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
        outputServerLog("[VENDRIX][TEST][FAIL] Query could not be queued.")
    end
end)
