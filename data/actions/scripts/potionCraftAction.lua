function onUse(cid, item, fromPosition, itemEx, toPosition)
    if PotionCraft and PotionCraft.active[cid] then
        doPlayerSendCancel(cid, "Você já está produzindo poções.")
        return true
    end

    if PotionCraft and PotionCraft.getOpenPayload then
        doSendPlayerExtendedOpcode(cid, 215, PotionCraft.getOpenPayload())
    else
        doSendPlayerExtendedOpcode(cid, 215, '{"action":"open"}')
    end
    return true
end
