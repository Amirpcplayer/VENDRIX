local function onDatabaseComplete(requestId, result, affectedRows, lastInsertId, errorCode, errorMessage)
    local item = VENDRIX_ACCOUNTS_getPending(requestId)
    if not item then
        return
    end

    local player = item.player
    if not isElement(player) then
        return
    end

    if item.action == "register_insert" then
        if result == false then
            local code = tonumber(errorCode) == 1062 and "username_taken" or "register_failed"
            VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:registerResult", false, code)
            return
        end

        VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:registerResult", true, "registered")
        return
    end

    if item.action == "login_lookup" then
        if type(result) ~= "table" or not result[1] then
            VENDRIX_ACCOUNTS_recordLogin(nil, item.username, false, "invalid_credentials")
            VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:loginResult", false, "invalid_credentials")
            return
        end

        local row = result[1]
        if tonumber(row.status) ~= 1 then
            VENDRIX_ACCOUNTS_recordLogin(tonumber(row.id), item.username, false, "invalid_credentials")
            VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:loginResult", false, "invalid_credentials")
            return
        end

        local verifyRequestId = VENDRIX_ACCOUNTS_beginPasswordVerification(
            player,
            item.username,
            item.password,
            tonumber(row.id),
            row.password_hash
        )
        if not verifyRequestId then
            VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:loginResult", false, "login_failed")
        end
        item.password = nil
        return
    end

    if item.action == "password_update" then
        if result == false then
            VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:passwordResult", false, "password_update_failed")
            return
        end

        VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:passwordResult", true, "password_changed")
    end
end

addEvent("onVendrixDatabaseQueryComplete", false)
addEventHandler("onVendrixDatabaseQueryComplete", resourceRoot, onDatabaseComplete)

addEvent("vendrix:accounts:register", true)
addEventHandler("vendrix:accounts:register", root, function(username, password)
    local player = client
    if not player or source ~= player or not VENDRIX_ACCOUNTS_canRequest(player) then
        return
    end

    if isPlayerAuthenticated(player) then
        VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:registerResult", false, "already_authenticated")
        return
    end

    if not VENDRIX_ACCOUNTS_validUsername(username) then
        VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:registerResult", false, "invalid_username")
        return
    end

    if not VENDRIX_ACCOUNTS_validPassword(password) then
        VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:registerResult", false, "invalid_password")
        return
    end

    passwordHash(password, "bcrypt", { cost = VENDRIX_ACCOUNTS.BCRYPT_COST }, function(hashedPassword)
        if not isElement(player) then
            return
        end

        if type(hashedPassword) ~= "string" then
            VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:registerResult", false, "hash_failed")
            return
        end

        local queued = VENDRIX_ACCOUNTS_queueRequest(
            player,
            "register_insert",
            [[
                INSERT INTO accounts (username, password_hash, password_algorithm, status)
                VALUES (?, ?, 'bcrypt', 1)
            ]],
            username,
            hashedPassword
        )

        if not queued then
            VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:registerResult", false, "database_unavailable")
        end
    end)
end)

addEvent("vendrix:accounts:login", true)
addEventHandler("vendrix:accounts:login", root, function(username, password)
    local player = client
    if not player or source ~= player or not VENDRIX_ACCOUNTS_canRequest(player) then
        return
    end

    if isPlayerAuthenticated(player) then
        VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:loginResult", false, "already_authenticated")
        return
    end

    if not VENDRIX_ACCOUNTS_validUsername(username)
        or not VENDRIX_ACCOUNTS_validPassword(password) then
        VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:loginResult", false, "invalid_credentials")
        return
    end

    local queued = VENDRIX_ACCOUNTS_queueRequest(
        player,
        "login_lookup",
        "SELECT id, password_hash, status FROM accounts WHERE username = ? LIMIT 1",
        username
    )

    if not queued then
        VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:loginResult", false, "database_unavailable")
        return
    end

    local requestId = nextRequestId
    pending[requestId].username = username
    pending[requestId].password = password
end)

addEvent("vendrix:accounts:logout", true)
addEventHandler("vendrix:accounts:logout", root, function()
    local player = client
    if not player or source ~= player or not isPlayerAuthenticated(player) then
        return
    end

    VENDRIX_ACCOUNTS_destroySession(player)
    VENDRIX_ACCOUNTS_sendResult(player, "vendrix:accounts:logoutResult", true, "logged_out")
end)
