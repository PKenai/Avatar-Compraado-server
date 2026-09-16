function onSay(cid, words, param, channel)
    if not isPlayer(cid) or getPlayerGroupId(cid) < 5 then
        return true
    end

    local level = tonumber(param)
    if not level then
        doPlayerSendCancelMessage(cid, "Usage: /light <level> (40-250)")
        return true
    end

    level = math.max(40, math.min(250, level))
    setWorldLight(level)
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "World light set to " .. level)
    return true
end
