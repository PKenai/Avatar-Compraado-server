-- ============================================================
-- WEAPON PROFICIENCY COMBAT HOOK (onStatsChange)
-- Aplica Life/Mana Leech, Reducao de Dano, Burn (Fire) e Dodge (Air).
-- Life/Mana leech: quando o jogador causa dano (qualquer origem).
-- Reducao de dano: quando o jogador recebe dano.
-- Burn: Fire bender causa dano -> chance de aplicar queimadura.
-- Dodge: Air bender recebe dano -> chance de esquivar completamente.
-- ============================================================

if type(WeaponProficiency) ~= "table" then
    dofile(getDataDir() .. "lib/weaponProficiency.lua")
end

if type(TalentPassives) ~= "table" then
    dofile(getDataDir() .. "lib/talentPassives.lua")
end

-- Vocacoes de Fire Bender (base + promoted)
local FIRE_VOCATIONS = { [1] = true, [5] = true }
-- Vocacoes de Air Bender (base + promoted)
local AIR_VOCATIONS  = { [3] = true, [7] = true }

function onStatsChange(cid, attacker, statType, combat, value)
    if statType ~= STATSCHANGE_HEALTHLOSS or math.abs(value) <= 0 then
        return true
    end

    local damage = math.abs(value)

    -- -------------------------------------------------------
    -- DODGE (Air Bender): cancela dano recebido por esquiva
    -- -------------------------------------------------------
    if isPlayer(cid) then
        local voc = getPlayerVocation(cid)
        if AIR_VOCATIONS[voc] then
            if TalentPassives.tryDodge(cid) then
                return false  -- cancela o dano completamente
            end
        end
    end

    -- -------------------------------------------------------
    -- ATACANTE: Life/Mana Leech + Burn (Fire Bender)
    -- -------------------------------------------------------
    if attacker and isPlayer(attacker) and cid ~= attacker then
        local bonuses = WeaponProficiency and WeaponProficiency.getActiveBonuses(attacker)
        if bonuses then
            if bonuses.lifeLeechChance and bonuses.lifeLeechChance > 0 and
               math.random(1, 100) <= bonuses.lifeLeechChance then
                local heal = math.max(1, math.ceil(damage * (bonuses.lifeLeechAmount or 0) / 100))
                doCreatureAddHealth(attacker, heal)
                doSendMagicEffect(getCreaturePosition(attacker), CONST_ME_MAGIC_RED)
            end

            if bonuses.manaLeechChance and bonuses.manaLeechChance > 0 and
               math.random(1, 100) <= bonuses.manaLeechChance then
                local mana = math.max(1, math.ceil(damage * (bonuses.manaLeechAmount or 0) / 100))
                setCreatureMana(attacker, getCreatureMana(attacker) + mana)
                doSendMagicEffect(getCreaturePosition(attacker), CONST_ME_MAGIC_BLUE)
            end
        end

        -- BURN (Fire Bender): tenta aplicar queimadura no alvo ao causar dano
        if FIRE_VOCATIONS[getPlayerVocation(attacker)] then
            TalentPassives.tryTriggerBurn(attacker, cid, damage)
        end
    end

    -- -------------------------------------------------------
    -- DEFENSOR: Reducao de dano (WeaponProficiency + Talent Armor)
    -- -------------------------------------------------------
    if isPlayer(cid) then
        local totalReduction = 0
        if WeaponProficiency then
            local bonuses = WeaponProficiency.getActiveBonuses(cid)
            totalReduction = (bonuses and bonuses.damageReduction) or 0
        end

        local talentArmor = getPlayerStorageValue(cid, "talentArmorBonus")
        if type(talentArmor) == "number" and talentArmor > 0 then
            totalReduction = totalReduction + talentArmor
        end

        if totalReduction > 0 then
            local reduced = math.max(1, math.ceil(damage * totalReduction / 100))
            doCreatureAddHealth(cid, reduced)
        end
    end

    return true
end
