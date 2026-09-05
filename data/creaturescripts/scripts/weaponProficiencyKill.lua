-- ============================================================
-- WEAPON PROFICIENCY KILL LISTENER
-- Concede experiencia na arma equipada ao derrotar monstros.
-- ============================================================

if type(WeaponProficiency) ~= "table" then
    dofile(getDataDir() .. "lib/weaponProficiency.lua")
end

function onKill(cid, target, lastHit)
    if not isPlayer(cid) or not isMonster(target) then
        return true
    end

    -- Ignora summons
    if isSummon(target) then
        return true
    end

    local equipped = WeaponProficiency.getEquippedWeapon(cid)
    if not equipped then
        return true
    end

    -- XP da luva = mesma experiencia que o monstro concede ao player
    -- (base do monstro; com rate 1.0 do servidor e exatamente o que o player recebe)
    local expGained = 0
    local monsterName = getCreatureName(target)
    if monsterName then
        local minfo = getMonsterInfo(monsterName)
        if minfo and minfo.experience and minfo.experience > 0 then
            expGained = minfo.experience
        end
    end

    -- Fallback: estima pela vida maxima do monstro
    if expGained <= 0 then
        local maxHealth = getCreatureMaxHealth(target) or 100
        expGained = math.max(5, math.floor(maxHealth / 25))
    end

    -- Concede a experiencia da arma
    WeaponProficiency.addWeaponExperience(cid, expGained)

    -- Feedback: sempre no console do servidor; no jogo apenas se storage 89202 == 1
    -- (ativar com: /weaponprof expmsg)
    print(string.format("[WeaponProficiency] +%d XP em %s (cid %s)", expGained, equipped.name, tostring(cid)))
    if getPlayerStorageValue(cid, 89202) == 1 then
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE,
            string.format("[Weapon Proficiency] +%d XP em %s.", expGained, equipped.name))
    end

    -- Aplica perks de regeneracao no abate (ex: Swift Recovery)
    local bonuses = WeaponProficiency.getActiveBonuses(cid)
    if bonuses.hpOnKill and bonuses.hpOnKill > 0 then
        doCreatureAddHealth(cid, bonuses.hpOnKill)
    end
    if bonuses.mpOnKill and bonuses.mpOnKill > 0 then
        doCreatureAddMana(cid, bonuses.mpOnKill)
    end

    return true
end
