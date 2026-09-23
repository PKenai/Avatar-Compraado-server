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

-- Guarda de reentrada da reducao de dano (mesma ideia do "antiloop" do imuneable.lua)
local REDUCTION_LOOP_KEY = "proficiencyDamageLoop"

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
    --
    -- NAO use doCreatureAddHealth() para "reduzir" o dano: o binding
    -- (luascript.cpp -> luaDoCreatureAddHealth) despacha valor positivo como
    -- COMBAT_HEALING, ou seja, CURARIA o defensor. Era o que estava aqui: a cada
    -- hit o jogador GANHAVA vida em vez de perder. Como o dano e' limitado a vida
    -- atual (game.cpp: damage = std::min(target->getHealth(), damage)), com 1 de
    -- vida o resultado era um empate eterno: o monstro tirava 1 e o script
    -- devolvia 1, e mais nada conseguia matar o personagem.
    --
    -- A reducao de verdade e' feita do jeito que o resto do datapack faz
    -- (imuneable.lua): cancela o dano original com return false e reenvia o valor
    -- ja' reduzido via doTargetCombatHealth, com uma trava de reentrada.
    -- -------------------------------------------------------
    if isPlayer(cid) and isCreature(attacker) then
        local totalReduction = 0
        if WeaponProficiency then
            local bonuses = WeaponProficiency.getActiveBonuses(cid)
            totalReduction = (bonuses and bonuses.damageReduction) or 0
        end

        local talentArmor = getPlayerStorageValue(cid, "talentArmorBonus")
        if type(talentArmor) == "number" and talentArmor > 0 then
            totalReduction = totalReduction + talentArmor
        end

        if totalReduction >= 100 then
            totalReduction = 99 -- nenhum hit real pode ser absorvido 100%
        end

        if totalReduction > 0 then
            -- Dano gerado por script (outro handler): nao reduzir de novo.
            -- Sao esses reenvios cruzados que estouravam o limite de 21 chamadas
            -- Lua simultaneas do motor. Ver data/lib/combatRecursionGuard.lua.
            if CombatRecursionGuard.isInside() then
                if getPlayerStorageValue(cid, REDUCTION_LOOP_KEY) == 1 then
                    setPlayerStorageValue(cid, REDUCTION_LOOP_KEY, -1)
                end
                return true
            end

            -- Reentrada: este e' o dano reduzido que nos mesmos reenviamos.
            if getPlayerStorageValue(cid, REDUCTION_LOOP_KEY) == 1 then
                setPlayerStorageValue(cid, REDUCTION_LOOP_KEY, -1)
                return true
            end

            local absorbed = math.floor(damage * totalReduction / 100)
            local reduced = damage - absorbed
            if reduced < 1 then
                reduced = 1
            end

            setPlayerStorageValue(cid, REDUCTION_LOOP_KEY, 1)
            CombatRecursionGuard.run(doTargetCombatHealth, attacker, cid, combat, -reduced, -reduced, -1)
            return false
        end
    end

    return true
end
