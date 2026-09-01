-- Recompensa 30k - Usagem unica (actionid 50004)
-- Da 30.000 gold (30 platinum coins) para players level 50+.
-- So pode ser usado uma vez por player.

local REWARD_COINS = 2152      -- platinum coin
local REWARD_COUNT = 30         -- 30 platinum = 30.000 gold
local MIN_LEVEL = 50
local USED_STORAGE = 50004

function onUse(cid, item, fromPosition, itemEx, toPosition)
    -- Verifica level
    local level = getPlayerLevel(cid)
    if level < MIN_LEVEL then
        doPlayerSendCancel(cid, "Voce precisa ser level " .. MIN_LEVEL .. " ou mais para usar isto.")
        return true
    end

    -- Verifica se ja usou
    local used = getPlayerStorageValue(cid, USED_STORAGE)
    if used >= 1 then
        doPlayerSendCancel(cid, "Voce ja usou esta recompensa antes.")
        return true
    end

    -- Da a recompensa
    doPlayerAddItem(cid, REWARD_COINS, REWARD_COUNT)
    setPlayerStorageValue(cid, USED_STORAGE, 1)
    doSendMagicEffect(getCreaturePosition(cid), CONST_ME_MAGIC_BLUE)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "Voce recebeu 30.000 gold!")
    return true
end
