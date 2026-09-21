-- ============================================================================
-- Pergaminhos da loja (categoria "Use")
--   18867 - Pergaminho da experiencia : +50% de experiencia por 45 minutos
--   18866 - Pergaminho da bencao      : bencao (bless) ate a proxima morte
--   18865 - Pergaminho do despertar   : estado Avatar por 5 minutos
-- ============================================================================

local EXP_SCROLL_TIME   = 45 * 60            -- 45 minutos (segundos)
local AVATAR_SCROLL_TIME = 5 * 60 * 1000     -- 5 minutos (milissegundos, p/ addEvent)

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if item.itemid == 18867 then
        return useExpScroll(cid, item)
    elseif item.itemid == 18866 then
        return useBlessScroll(cid, item)
    elseif item.itemid == 18865 then
        return useAwakenScroll(cid, item)
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Pergaminho da experiencia (18867)
-- O bonus e aplicado/mantido pelo checkExpRates (data/creaturescripts/scripts/
-- idle.lua): ele le o storage hasExpScroll a cada think e adiciona +0.5 ao
-- rate enquanto o tempo nao expirar. Nao setamos o rate aqui para nao
-- sobrescrever o combo que o checkExpRates calcula (premium/stamina/etc).
-- ---------------------------------------------------------------------------
function useExpScroll(cid, item)
    if (tonumber(getPlayerStorageValue(cid, "hasExpScroll")) or 0) > os.time() then
        doPlayerSendCancel(cid, getLangString(cid, "You already have an experience scroll active.", "Você já está sob o efeito de um pergaminho de experiência."))
        return false
    end

    local endTime = os.time() + EXP_SCROLL_TIME
    setPlayerStorageValue(cid, "hasExpScroll", endTime)
    doCreatureAddBuffWithTime(cid, 11, EXP_SCROLL_TIME * 1000) -- buff icon com timer
    doSendMagicEffect(getThingPos(cid), 13)
    doRemoveItem(item.uid, 1)
    sendBlueMessage(cid, getLangString(cid, "Your experience gain was increased by 50% for 45 minutes!", "Seu ganho de experiência foi aumentado em 50% por 45 minutos!"))
    return true
end

-- ---------------------------------------------------------------------------
-- Pergaminho da bencao (18866)
-- Mesma bencao que o NPC de bless (data/npc/scripts/bless.lua): o deathChecks
-- le o storage playerWithBless na morte e aplica -50% de experiencia perdida.
-- ---------------------------------------------------------------------------
function useBlessScroll(cid, item)
    if getPlayerStorageValue(cid, "playerWithBless") == 1 then
        doPlayerSendCancel(cid, getLangString(cid, "You are already blessed.", "Você já está abençoado."))
        return false
    end

    setPlayerStorageValue(cid, "playerWithBless", 1)
    setPlayerStorageValue(cid, "blessExpName", "Pergaminho da benção")
    doSendMagicEffect(getThingPos(cid), 29)
    doRemoveItem(item.uid, 1)
    sendBlueMessage(cid, getLangString(cid, "You received the blessing! You will lose 50% less experience on your next death.", "Você recebeu a benção! Perderá 50% menos experiência na sua próxima morte."))
    return true
end

-- ---------------------------------------------------------------------------
-- Pergaminho do despertar (18865)
-- Coloca o jogador no estado Avatar (storage isAvatar = 1, mesmo do evento
-- avatar.lua) por 5 minutos e depois restaura o valor anterior. Se o jogador
-- ja e o Avatar do evento, nao faz nada para nao corromper o estado.
-- ---------------------------------------------------------------------------
function useAwakenScroll(cid, item)
    local wasAvatar = getPlayerStorageValue(cid, "isAvatar")
    if wasAvatar == 1 then
        doPlayerSendCancel(cid, getLangString(cid, "You are already in the Avatar State.", "Você já está no estado Avatar."))
        return false
    end

    setPlayerStorageValue(cid, "isAvatar", 1)
    local pos = getCreaturePosition(cid)
    doSendMagicEffect({x = pos.x + 1, y = pos.y + 1, z = pos.z}, 134)
    doSendMagicEffect({x = pos.x + 1, y = pos.y + 1, z = pos.z}, 135)
    doSendMagicEffect({x = pos.x + 1, y = pos.y + 1, z = pos.z}, 121)
    doRemoveItem(item.uid, 1)
    sendBlueMessage(cid, getLangString(cid, "The Avatar State has awakened within you for 5 minutes!", "O estado Avatar despertou em você por 5 minutos!"))

    -- Seguranca contra reuso de cid (relog): guarda guid+nome e confere antes de restaurar
    local guid = getPlayerGUID(cid)
    local name = getCreatureName(cid)
    addEvent(function()
        local target = getPlayerByNameWildcard(name)
        if target and isPlayer(target) and getPlayerGUID(target) == guid then
            setPlayerStorageValue(target, "isAvatar", wasAvatar)
            doSendMagicEffect(getThingPos(target), 121)
            doPlayerSendTextMessage(target, MESSAGE_INFO_DESCR, getLangString(target, "The Avatar State has faded away.", "O estado Avatar se desfez."))
        end
    end, AVATAR_SCROLL_TIME)
    return true
end
