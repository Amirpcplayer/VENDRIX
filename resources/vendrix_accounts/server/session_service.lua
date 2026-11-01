local activeAccounts = {}
local playerAccounts = {}

function isPlayerAuthenticated(player)
    return isElement(player)
        and getElementType(player) == "player"
        and playerAccounts[player] ~= nil
end

function getPlayerAccountId(player)
    if not isPlayerAuthenticated(player) then
        return false
    end

    return playerAccounts[player]
end

local function releasePlayerSession(player)
    local accountId = playerAccounts[player]
    if not accountId then
        return
    end

    if activeAccounts[accountId] == player then
        activeAccounts[accountId] = nil
    end

    playerAccounts[player] = nil
end

function VENDRIX_ACCOUNTS_createSession(player, accountId)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false, "invalid_player"
    end

    if playerAccounts[player] then
        return false, "player_already_authenticated"
    end

    local existingPlayer = activeAccounts[accountId]
    if existingPlayer and isElement(existingPlayer) then
        return false, "account_already_active"
    end

    activeAccounts[accountId] = player
    playerAccounts[player] = accountId
    setElementData(player, "vendrix:authenticated", true, false)
    setElementData(player, "vendrix:accountId", accountId, false)
    setElementFrozen(player, false)

    return true
end

function VENDRIX_ACCOUNTS_destroySession(player)
    if not isElement(player) then
        return false
    end

    releasePlayerSession(player)
    removeElementData(player, "vendrix:authenticated")
    removeElementData(player, "vendrix:accountId")
    setElementFrozen(player, true)
    return true
end

addEventHandler("onPlayerJoin", root, function()
    setElementFrozen(source, true)
end)

addEventHandler("onPlayerQuit", root, function()
    releasePlayerSession(source)
end)

addEventHandler("onResourceStart", resourceRoot, function()
    for _, player in ipairs(getElementsByType("player")) do
        if not isPlayerAuthenticated(player) then
            setElementFrozen(player, true)
        end
    end
end)

addEventHandler("onResourceStop", resourceRoot, function()
    for player in pairs(playerAccounts) do
        if isElement(player) then
            removeElementData(player, "vendrix:authenticated")
            removeElementData(player, "vendrix:accountId")
            setElementFrozen(player, true)
        end
    end

    activeAccounts = {}
    playerAccounts = {}
end)
