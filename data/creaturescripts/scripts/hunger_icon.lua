dofile(getDataDir() .. "lib/custom/hunger_icon_lib.lua")
dofile(getDataDir() .. "lib/custom/nomana_icon_lib.lua")

-- ============================================================================
-- WATCHDOG DE TRAVA DE MOVIMENTO (doCreatureSetNoMove)
-- ----------------------------------------------------------------------------
-- doCreatureSetNoMove(cid, true) e' uma trava BOOLEANA no objeto do player:
-- nao tem prazo, so' sai com um destrava explicito. Quem trava (voo do Appa,
-- armadilha de ar, portal/teleport, porta de sala, minigame, feitico de gelo)
-- deveria destravar no fim, e quando um desses destravas se perde o jogador
-- fica sem dar UM passo - "paralisado" - ate' o relogin, em qualquer lugar,
-- inclusive em protection zone onde nada pode ter aplicado aquilo.
--
-- O comportamento principal (e a causa dos destravas que nao funcionavam) esta
-- em Creature::setNoMove (sources/creature.h). Aqui e' a rede de seguranca:
-- so' age quando NADA conhecido justifica a trava, e sempre com log no console
-- dizendo quem estava travado. Assim o caso que aparecer no console aponta a
-- origem exata no proximo relatorio.
-- ============================================================================
MOVELOCK_AUDIT = true -- false desliga o auto-destrava
local MOVELOCK_LIMIT = 6 -- ~30s de trava consecutiva sem causa antes de destravar

local stuckTicks = {} -- [cid] = quantas varreduras seguidas esta' travado (sem storage)

local function hasParalyzeCondition(cid)
    local paralyze = rawget(_G, "CONDITION_PARALYZE")
    if type(paralyze) ~= "number" then
        return false
    end
    return getCreatureCondition(cid, paralyze) and true or false
end

-- Tudo o que trava o movimento de proposito: enquanto qualquer um destes valer,
-- o watchdog fica quieto (a trava e' legitima e quem a fez vai soltar).
local function moveLockIsExpected(cid)
    if hasParalyzeCondition(cid) then
        return true, "CONDITION_PARALYZE"
    end
    if type(exhaustion) == "table" and exhaustion.check(cid, "airtrapped") then
        return true, "airtrap"
    end
    if type(isAppaFlying) == "function" and isAppaFlying(cid) then
        return true, "voo do Appa"
    end

    local tile = getTileInfo(getThingPos(cid))
    if tile and (tile.noLogout or tile.protection) then
        return true, "sala de evento/PZ"
    end
    return false
end

local function checkMoveLock(cid)
    if not MOVELOCK_AUDIT or not getCreatureNoMove(cid) then
        stuckTicks[cid] = nil
        return
    end

    local expected, why = moveLockIsExpected(cid)
    if expected then
        stuckTicks[cid] = nil
        return
    end

    stuckTicks[cid] = (stuckTicks[cid] or 0) + 1
    if stuckTicks[cid] < MOVELOCK_LIMIT then
        return
    end

    stuckTicks[cid] = nil
    print(string.format(
        "[MoveLock] %s estava sem poder andar (noMove=true) sem nenhuma causa conhecida em %d varreduras seguidas; destravando.",
        tostring(getCreatureName(cid)), MOVELOCK_LIMIT))
    doCreatureSetNoMove(cid, false)
end

-- Creature event: Hunger + NoMana Icons
-- Fires every ~5 seconds for each registered player.
-- Checks food status and mana %, broadcasts opcodes when state changes.
function onThink(cid, interval)
    if not isPlayer(cid) then return true end
    HUNGER_ICON.checkAndUpdate(cid)
    NOMANA_ICON.checkAndUpdate(cid)

    -- Rede de seguranca da velocidade (data/lib/248-playerSpeed.lua): devolve
    -- slows temporarios vencidos e conserta velocidade que caiu abaixo do
    -- esperado sem nenhuma paralisia ativa (o servidor cancela a walk quando a
    -- speed chega a 0 - e' a "paralisia" que so' saia com relogin).
    if type(PlayerSpeed) == "table" then
        if PlayerSpeed.sweep then PlayerSpeed.sweep() end
        if PlayerSpeed.audit then PlayerSpeed.audit(cid) end
    end

    -- Rede de seguranca da trava de movimento (setNoMove).
    checkMoveLock(cid)

    return true
end
