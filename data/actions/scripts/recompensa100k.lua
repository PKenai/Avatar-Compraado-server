--[[
 * recompensa100k - action registrada em data/actions/actions.xml com
 * actionid 50001: ao USAR o item do mapa que tiver esse action id, o player
 * recebe 10 crystal coins. Regras:
 *   - apenas level 120+ pode usar
 *   - so pode usar UMA UNICA VEZ (storage "recompensa100k" = 1)
 * Tambem marca storage "aianoChest" = 1 (o bau e o "tesouro" da quest do
 * NPC Aiano - o jogador precisa usa-lo para receber a peca do set dele).
]]

local STORAGE_USED = "recompensa100k"
local GOLD_ID = 2160 -- crystal coin
local GOLD_AMOUNT = 10
local MIN_LEVEL = 120

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if not isPlayer(cid) then
        return false
    end

    if getPlayerStorageValue(cid, STORAGE_USED) == 1 then
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Voce ja usou esta recompensa.")
        return true
    end

    if getPlayerLevel(cid) < MIN_LEVEL then
        doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Voce precisa de level 120 para usar isto.")
        return true
    end

    setPlayerStorageValue(cid, STORAGE_USED, 1)
    setPlayerStorageValue(cid, "aianoChest", 1) -- quest do Aiano: pegou o bau do tesouro
    doPlayerAddItem(cid, GOLD_ID, GOLD_AMOUNT)
    doSendMagicEffect(getThingPos(cid), 38) -- gold rings
    doPlayerSendTextMessage(cid, MESSAGE_INFO_DESCR, "Voce recebeu 10 crystal coins!")

    return true
end
