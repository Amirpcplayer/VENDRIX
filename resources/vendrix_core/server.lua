-- Minimal VENDRIX core lifecycle hooks. No gameplay systems in phase 1.

local function log(level, message)
    outputServerLog(("[VENDRIX][%s][core] %s"):format(level, message))
end

addEventHandler("onResourceStart", resourceRoot, function()
    log("INFO", "Core resource started.")
end)

addEventHandler("onPlayerJoin", root, function()
    log("INFO", "Player joined; no persistent state has been created.")
end)

addEventHandler("onPlayerQuit", root, function()
    -- Future transient state cleanup belongs here once such state exists.
end)

addEventHandler("onResourceStop", resourceRoot, function()
    log("INFO", "Core resource stopped.")
end)
