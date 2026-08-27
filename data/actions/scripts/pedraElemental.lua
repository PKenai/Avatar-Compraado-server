-- Pedras Elementais (19002-19006)
-- Ao usar, verifica se o player é o dobrador correspondente.
-- Se sim, verifica se não passou de 50 pontos (via MySQL).
-- Remove a pedra, soma 1 ponto no MySQL e dá 1 ponto pendente de atributo.
-- A tabela MySQL 'pedra_elemental' rastreia o total de pontos por player.
-- O reset de atributos deve zerar essa tabela (UPDATE pedra_elemental SET pontos = 0 WHERE player_id = X).

local PEDRAS_CONFIG = {
    [19002] = {elemento = "ar",     vocationId = 3, nome = "Pedra elemental do ar",     nomeEN = "Elemental Air Stone"},
    [19003] = {elemento = "agua",   vocationId = 2, nome = "Pedra elemental da agua",   nomeEN = "Elemental Water Stone"},
    [19005] = {elemento = "fogo",   vocationId = 1, nome = "Pedra elemental do fogo",   nomeEN = "Elemental Fire Stone"},
    [19006] = {elemento = "terra",  vocationId = 4, nome = "Pedra elemental da terra",  nomeEN = "Elemental Earth Stone"}
}

local MAX_PONTOS_PEDRAS = 50

-- Obtém o base vocation (1-4, sem promoção)
local function getBaseVocation(cid)
    local voc = getPlayerVocation(cid)
    if voc >= 5 and voc <= 8 then
        return voc - 4
    end
    return voc
end

-- Obtém a quantidade atual de pontos de pedra do player (MySQL)
local function getPontosPedra(cid)
    local guid = getPlayerGUID(cid)
    local result = db.getResult("SELECT pontos FROM pedra_elemental WHERE player_id = " .. guid)
    if result:getID() ~= -1 then
        local pontos = result:getDataInt("pontos")
        result:free()
        return pontos
    end
    return 0
end

-- Adiciona 1 ponto de pedra no MySQL (INSERT ou UPDATE)
local function adicionarPontosPedra(cid)
    local guid = getPlayerGUID(cid)
    local pontosAtuais = getPontosPedra(cid)

    if pontosAtuais == 0 then
        -- Primeira vez: insere
        db.executeQuery("INSERT INTO pedra_elemental (player_id, pontos) VALUES (" .. guid .. ", 1)")
    else
        -- Atualiza
        db.executeQuery("UPDATE pedra_elemental SET pontos = " .. (pontosAtuais + 1) .. " WHERE player_id = " .. guid)
    end

    return pontosAtuais + 1
end

function onUse(cid, item, fromPosition, itemEx, toPosition)
    local config = PEDRAS_CONFIG[item.itemid]
    if not config then
        return false
    end

    -- Verifica se é o dobrador correto
    local baseVoc = getBaseVocation(cid)
    if baseVoc ~= config.vocationId then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
            getLangString(cid,
                "Only " .. config.elemento .. " benders can use this stone!",
                "Apenas dobradores de " .. config.elemento .. " podem usar esta pedra!"))
        return true
    end

    -- Verifica limite de 50 pontos
    local pontosAtuais = getPontosPedra(cid)
    if pontosAtuais >= MAX_PONTOS_PEDRAS then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
            getLangString(cid,
                "You have reached the maximum of " .. MAX_PONTOS_PEDRAS .. " elemental stone points!",
                "Você já atingiu o máximo de " .. MAX_PONTOS_PEDRAS .. " pontos de pedras elementais!"))
        return true
    end

    -- Remove a pedra
    doRemoveItem(item.uid, 1)

    -- Adiciona 1 ponto no MySQL
    local novosPontos = adicionarPontosPedra(cid)

    -- Adiciona 1 ponto pendente de atributo
    local pendentes = getPlayerStorageValue(cid, "pendentes")
    if type(pendentes) ~= "number" or pendentes < 0 then
        pendentes = 0
    end
    pendentes = pendentes + 1
    setPlayerStorageValue(cid, "pendentes", pendentes)

    -- Atualiza o display de atributos
    doSendPlayerExtendedOpcode(cid, 41, tostring(pendentes))
    if getAtributosString then
        doSendPlayerExtendedOpcode(cid, 40, getAtributosString(cid))
    end

    -- Efeitos e mensagens
    doSendMagicEffect(getCreaturePosition(cid), 28)

    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
        getLangString(cid,
            config.nomeEN .. " absorbed! +1 attribute point. (" .. novosPontos .. "/" .. MAX_PONTOS_PEDRAS .. " stone points used)",
            config.nome .. " absorvida! +1 ponto de atributo. (" .. novosPontos .. "/" .. MAX_PONTOS_PEDRAS .. " pontos de pedra usados)"))

    -- Avisa se está perto do limite
    if novosPontos == MAX_PONTOS_PEDRAS - 5 and novosPontos > 0 then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
            getLangString(cid,
                "Warning: You are close to the maximum of " .. MAX_PONTOS_PEDRAS .. " elemental stone points!",
                "Atenção: Você está perto do limite de " .. MAX_PONTOS_PEDRAS .. " pontos de pedras elementais!"))
    end

    return true
end
