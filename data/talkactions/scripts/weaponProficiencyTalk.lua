-- ============================================================
-- WEAPON PROFICIENCY TALKACTION (/weaponprof)
-- Permite testar, gerenciar e inspecionar a maestria de armas.
-- ============================================================

if type(WeaponProficiency) ~= "table" then
    dofile(getDataDir() .. "lib/weaponProficiency.lua")
end

function onSay(cid, words, param)
    if not isPlayer(cid) then
        return true
    end

    param = param:trim()
    local split = param:explode(",")
    local action = split[1] and split[1]:trim():lower() or "help"

    local equipped = WeaponProficiency.getEquippedWeapon(cid)

    if action == "info" then
        if not equipped then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Weapon Proficiency] Nenhuma arma equipada no momento.")
            return true
        end

        local prof = WeaponProficiency.getWeaponProficiency(cid, equipped.id)
        local level = WeaponProficiency.getLevelByExperience(prof.exp)
        local nextExp = WeaponProficiency.LevelExperience[math.min(level + 1, WeaponProficiency.MAX_LEVEL)] or prof.exp

        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, 
            string.format("=== WEAPON PROFICIENCY ===\nArma: %s\nNivel: %d / %d\nExperiencia: %d / %d", 
            equipped.name, level, WeaponProficiency.MAX_LEVEL, prof.exp, nextExp))

        local bonuses = WeaponProficiency.getActiveBonuses(cid)
        local bonusLines = {}
        if bonuses.critChance > 0 then table.insert(bonusLines, string.format("+%d%% Chance de Critico", bonuses.critChance)) end
        if bonuses.critDamage > 0 then table.insert(bonusLines, string.format("+%d%% Dano Critico", bonuses.critDamage)) end
        if bonuses.pyroDamage > 0 then table.insert(bonusLines, string.format("+%d%% Dano Pyro", bonuses.pyroDamage)) end
        if bonuses.physicalDamage > 0 then table.insert(bonusLines, string.format("+%d%% Dano Fisico", bonuses.physicalDamage)) end
        if bonuses.skillBoost > 0 then table.insert(bonusLines, string.format("+%d Weapon Skill", bonuses.skillBoost)) end
        if bonuses.damageReduction > 0 then table.insert(bonusLines, string.format("-%d%% Dano Recebido", bonuses.damageReduction)) end
        if bonuses.lifeLeechChance > 0 then table.insert(bonusLines, string.format("+%d%% Life Leech", bonuses.lifeLeechChance)) end
        if bonuses.manaLeechChance > 0 then table.insert(bonusLines, string.format("+%d%% Mana Leech", bonuses.manaLeechChance)) end

        if #bonusLines > 0 then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Bonus Ativos:\n- " .. table.concat(bonusLines, "\n- "))
        else
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Nenhum perk ativo nesta arma.")
        end

    elseif action == "addexp" then
        local amount = tonumber(split[2] and split[2]:trim())
        if not amount or amount <= 0 then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Uso: /weaponprof addexp, <quantidade>")
            return true
        end

        if not equipped then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Equipe uma arma primeiro.")
            return true
        end

        WeaponProficiency.addWeaponExperience(cid, amount)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, 
            string.format("[Weapon Proficiency] +%d de experiencia adicionado a arma %s.", amount, equipped.name))

    elseif action == "open" then
        WeaponProficiency.sendData(cid)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Weapon Proficiency] Janela sincronizada no client.")

    elseif action == "reset" then
        if not equipped then
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Equipe uma arma primeiro.")
            return true
        end

        local allData = WeaponProficiency.loadPlayerData(cid)
        allData[tostring(equipped.id)] = {
            exp = 0,
            level = 0,
            perks = {}
        }
        WeaponProficiency.savePlayerData(cid, allData)
        WeaponProficiency.sendData(cid)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Weapon Proficiency] Proficiencia da arma resetada.")

    elseif action == "expmsg" then
        local cur = getPlayerStorageValue(cid, 89202)
        if cur == 1 then
            setPlayerStorageValue(cid, 89202, 0)
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Weapon Proficiency] Mensagem de XP por abate desativada.")
        else
            setPlayerStorageValue(cid, 89202, 1)
            doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Weapon Proficiency] Mensagem de XP por abate ativada.")
        end

    elseif action == "reload" then
        dofile(getDataDir() .. "lib/weaponProficiency.lua")
        WeaponProficiency.sendData(cid)
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Weapon Proficiency] Lib recarregada com sucesso e dados sincronizados.")

    else
        doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, 
            "Comandos de Weapon Proficiency:\n" ..
            "- /weaponprof info (mostra dados da arma equipada e perks ativos)\n" ..
            "- /weaponprof addexp, <quant> (adiciona XP na arma equipada)\n" ..
            "- /weaponprof open (abre/sincroniza a interface no client)\n" ..
            "- /weaponprof reset (reseta a proficiencia da arma atual)\n" ..
            "- /weaponprof expmsg (ativa/desativa mensagem de XP por abate)\n" ..
            "- /weaponprof reload (recarrega os scripts do sistema)")
    end

    return true
end
