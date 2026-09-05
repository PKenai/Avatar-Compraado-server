-- ============================================================
-- WEAPON PROFICIENCY COMBAT HOOK (onStatsChange)
-- Aplica Life/Mana Leech e Reducao de Dano dos perks ativos.
-- Life/Mana leech: quando o jogador causa dano (qualquer origem).
-- Reducao de dano: quando o jogador recebe dano.
-- ============================================================

if type(WeaponProficiency) ~= "table" then
    dofile(getDataDir() .. "lib/weaponProficiency.lua")
end

function onStatsChange(cid, attacker, type, combat, value)
    -- Life/Mana Leech: jogador com perks de roubo causa dano
    if isPlayer(attacker) and value < 0 and combat == STATSCHANGE_HEALTHLOSS then
        local bonuses = WeaponProficiency.getActiveBonuses(attacker)
        local damage = math.abs(value)

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

    -- Reducao de dano: jogador com perks de tanque recebe dano
    if isPlayer(cid) and value < 0 and combat == STATSCHANGE_HEALTHLOSS then
        local bonuses = WeaponProficiency.getActiveBonuses(cid)
        if bonuses.damageReduction and bonuses.damageReduction > 0 then
            local reduced = math.max(1, math.ceil(math.abs(value) * bonuses.damageReduction / 100))
            doCreatureAddHealth(cid, reduced)
        end
    end

    return true
end
