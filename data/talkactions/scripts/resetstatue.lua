-- ============================================================================
-- !resetstatue - zera pool / encerra bencao da Estatua de Doacao (STAFF)
-- ----------------------------------------------------------------------------
--   !resetstatue                    mostra o estado atual (pools e bencaos)
--   !resetstatue all                zera TODOS os pools e encerra TODAS as bencaos
--   !resetstatue pools              zera so' os pools (bencao ativa continua)
--   !resetstatue blessings          encerra so' as bencaos (tira o buff de todo
--                                   mundo); os pools ficam como estavam
--   !resetstatue air                reset completo de UMA chave (pool + bencao)
--   !resetstatue air pool           so' o pool daquela chave
--   !resetstatue exp blessing       so' a bencao daquela chave
--
-- Chaves (data/lib/statueDonation.lua): fire, water, air, earth, exp, potion.
-- TODAS tem pool agora (as abas globais tambem): a bencao ativa quando a pool
-- bate a meta, e "<chave> pool" zera o acumulado sem mexer na bencao.
--
-- BUFF: encerrar a bencao limpa o icone de TODO mundo. Quem esta' online perde
-- na hora (o comando diz quantos foram) e quem esta' offline nao recebe nada no
-- proximo login/relogin, porque o icone e' derivado do estado (bonus_until = 0)
-- e a lib manda o "remove" de todas as chaves que nao valem mais.
--
-- Permissao: access 5 (God), igual ao !pixconfirm. A linha do talkactions.xml
-- tem log="yes", entao fica no log do servidor quem usou e com que parametro.
--
-- ATENCAO: e' reset de ESTADO, nao mexe em ouro. Pool que tinha doacao volta a
-- 0 (o ouro doado nao e' devolvido a ninguem) e o comando tambem NAO anuncia
-- nada no jogo - se quiser avisar os players, use o broadcast depois.
-- ============================================================================

local MIN_GROUP = 5 -- group id 5 = Community Manager (mesma trava do pixAdmin)

local function reply(cid, text)
    doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, text)
end

local function formatNumber(n)
    local text = tostring(math.floor(tonumber(n) or 0))
    text = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    text = text:gsub("^,", "")
    return text
end

local function showStatus(cid)
    local list, err = StatueDonation.adminList()
    if not list then
        reply(cid, "Falha ao ler o estado: " .. tostring(err))
        return
    end

    reply(cid, "Estatua de Doacao:")
    for _, entry in ipairs(list) do
        local state
        if entry.left > 0 then
            state = "ATIVA (" .. StatueDonation.formatTime(entry.left) .. " restantes) | pool " ..
                formatNumber(entry.pool) .. "/" .. formatNumber(entry.goal)
        else
            state = "pool " .. formatNumber(entry.pool) .. "/" .. formatNumber(entry.goal)
        end
        reply(cid, "  " .. entry.key .. " (" .. entry.label .. "): " .. state)
    end
end

local function reportOne(cid, info)
    local parts = {}
    table.insert(parts, "pool " .. formatNumber(info.poolBefore) .. " -> " .. formatNumber(info.poolAfter))

    if info.wasActive then
        if info.activeAfter then
            table.insert(parts, "bencao segue ATIVA (nao mexida)")
        else
            table.insert(parts, "bencao encerrada (faltavam " .. StatueDonation.formatTime(info.leftBefore) .. ")")
        end
    else
        table.insert(parts, "bencao ja' estava inativa")
    end

    if type(info.removed) == "number" then
        table.insert(parts, "icone tirado de " .. info.removed .. " player(s) online")
    end

    reply(cid, "  " .. info.key .. ": " .. table.concat(parts, " | "))
end

function onSay(cid, words, param, channel)
    if getPlayerGroupId(cid) < MIN_GROUP then
        reply(cid, "Voce nao tem permissao para usar este comando.")
        return true
    end

    param = (param or ""):gsub("^%s*(.-)%s*$", "%1"):lower()

    if param == "" then
        showStatus(cid)
        reply(cid, "Use: !resetstatue all | pools | blessings | <chave> [pool|blessing]")
        return true
    end

    local list, err = StatueDonation.adminList()
    if not list then
        reply(cid, "Falha ao ler o estado: " .. tostring(err))
        return true
    end

    local known, allKeys = {}, {}
    for _, entry in ipairs(list) do
        known[entry.key] = entry.kind
        table.insert(allKeys, entry.key)
    end

    local first, second = param:match("^(%S+)%s*(%S*)$")
    local keys, what = {}, "all"

    if second ~= "" then
        if second == "pool" or second == "pools" then
            what = "pool"
        elseif second == "blessing" or second == "blessings" then
            what = "blessing"
        elseif second == "all" then
            what = "all"
        else
            reply(cid, "Opcao '" .. second .. "' invalida. Use: <chave> pool | <chave> blessing.")
            return true
        end
    end

    if first == "all" or first == "*" then
        if second ~= "" then
            reply(cid, "all ja' inclui pools e bencoes. Use: !resetstatue all")
            return true
        end
        keys = allKeys
    elseif first == "pool" or first == "pools" then
        if second ~= "" then
            reply(cid, "Use: !resetstatue pools")
            return true
        end
        what = "pool"
        -- todas as chaves tem pool (nacoes e abas globais)
        keys = allKeys
    elseif first == "blessing" or first == "blessings" then
        if second ~= "" then
            reply(cid, "Use: !resetstatue blessings")
            return true
        end
        what = "blessing"
        keys = allKeys
    elseif known[first] then
        keys = { first }
    else
        reply(cid, "Chave '" .. first .. "' desconhecida. Chaves: " .. table.concat(allKeys, ", ") ..
            " (ou all / pools / blessings).")
        return true
    end

    if #keys == 0 then
        reply(cid, "Nada pra resetar (nenhuma chave nesse filtro).")
        return true
    end

    reply(cid, "Reset da estatua (" .. what .. "): " .. #keys .. " chave(s).")

    local failed = 0
    for _, key in ipairs(keys) do
        local ok, info = StatueDonation.resetKey(key, what)
        if ok then
            reportOne(cid, info)
        else
            failed = failed + 1
            reply(cid, "  " .. key .. ": FALHOU - " .. tostring(info))
        end
    end

    if failed > 0 then
        reply(cid, failed .. " chave(s) nao foram resetadas. Nada mudou nelas.")
    end

    if what ~= "pool" then
        reply(cid, "Offline: quem estiver fora perde o icone no proximo login/relogin - o estado novo nao reativa nada.")
    end
    return true
end
