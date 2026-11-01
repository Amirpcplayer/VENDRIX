-- Minimal authenticated-player spawn for the default GTA: San Andreas world.
-- No mapmanager or custom .map file is required for the base GTA world.

local SPAWN = {
    x = 2495.3,
    y = -1687.2,
    z = 13.5,
    rotation = 90,
    interior = 0,
    dimension = 0,
    skin = 0
}

local function spawnAuthenticatedPlayer(player, accountId)
    if not isElement(player) or getElementType(player) ~= "player"
        or not exports.vendrix_accounts:isPlayerAuthenticated(player) then
        return
    end

    local spawned = spawnPlayer(
        player,
        SPAWN.x,
        SPAWN.y,
        SPAWN.z,
        SPAWN.rotation,
        SPAWN.skin,
        SPAWN.interior,
        SPAWN.dimension
    )

    if not spawned then
        outputServerLog("[VENDRIX][spawn][ERROR] spawnPlayer failed for an authenticated player.")
        return
    end

    setElementFrozen(player, false)
    fadeCamera(player, true, 1.5)
    setCameraTarget(player, player)
    outputServerLog(("[VENDRIX][spawn][INFO] Account %d spawned in the default GTA world."):format(
        tonumber(accountId) or 0
    ))
end

addEvent("onVendrixPlayerAuthenticated", false)
addEventHandler("onVendrixPlayerAuthenticated", root, function(accountId)
    spawnAuthenticatedPlayer(source, accountId)
end)

addEventHandler("onPlayerJoin", root, function()
    setElementFrozen(source, true)
    fadeCamera(source, true, 0.5)
end)
