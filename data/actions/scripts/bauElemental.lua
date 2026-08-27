-- Baú Elemental (item 19004)
-- Ao usar, remove o bau e dropa 1 pedra elemental aleatória (25% cada)
-- 19002 = Pedra elemental do ar
-- 19003 = Pedra elemental da agua
-- 19005 = Pedra elemental do fogo
-- 19006 = Pedra elemental da terra

local pedrasElementais = {
    19002, -- ar
    19003, -- agua
    19005, -- fogo
    19006  -- terra
}

local nomesPedras = {
    [19002] = "Pedra elemental do ar",
    [19003] = "Pedra elemental da agua",
    [19005] = "Pedra elemental do fogo",
    [19006] = "Pedra elemental da terra"
}

function onUse(cid, item, fromPosition, itemEx, toPosition)
    -- Remove o bau
    doRemoveItem(item.uid, 1)

    -- Escolhe 1 pedra aleatória (25% cada)
    local pedraId = pedrasElementais[math.random(1, #pedrasElementais)]

    -- Dá a pedra ao player
    doPlayerAddItem(cid, pedraId, 1)

    -- Efeitos visuais
    doSendMagicEffect(getCreaturePosition(cid), 28)

    -- Mensagem
    local nomePedra = nomesPedras[pedraId]
    sendBlueMessage(cid, getLangString(cid,
        "You opened the Baú elemental and found: " .. nomePedra .. "!",
        "Você abriu o Baú elemental e encontrou: " .. nomePedra .. "!"))

    return true
end
