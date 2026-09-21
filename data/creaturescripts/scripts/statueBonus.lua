--[[
================================================================================
  STATUE DONATION - bonus de dano das nacoes (+5% contra MONSTROS)
--------------------------------------------------------------------------------
  Registrado como creatureevent "statschange" (StatueDonationCombat).

  Regra: se quem causou o dano e' um PLAYER cuja nacao esta' com o bonus ativo
  (pool bateu 150k), o dano contra MONSTRO ganha +5%.

  COMO O BONUS E' APLICADO
  - Dano extra somado via doTargetCombatHealth (atribuido ao atacante, entao
    conta exp/loot normalmente). NAO cancelamos e reenviamos o dano original:
    se o reenvio falhasse (alvo morreu/andou), o player PERDERIA o hit - aqui,
    no pior caso, ele so' perde os 5%.
  - A guarda de reentrada (storage) impede que o proprio dano extra dispare o
    bonus de novo. Mesma ideia do "antiloop" do imuneable.lua/proficiencyCombat.
  - PvP fica de fora de proposito (o pedido era "so' monstros").
================================================================================
]]

local LOOP_KEY = "statueDamageLoop"

function onStatsChange(cid, attacker, statType, combat, value)
    if statType ~= STATSCHANGE_HEALTHLOSS then
        return true
    end
    if not isPlayer(attacker) then
        return true
    end
    if cid == attacker then
        return true -- dano proprio nao ganha bonus
    end
    if not isMonster(cid) then
        return true -- PvE: player nao leva o bonus (PvP fora)
    end
    if type(StatueDonation) ~= "table" then
        return true
    end

    local element = StatueDonation.elementOf(attacker)
    if not element or not StatueDonation.isNationActive(element) then
        return true
    end

    local damage = math.abs(tonumber(value) or 0)
    if damage <= 0 then
        return true
    end

    -- reentrada: este e' o dano extra que nos mesmos mandamos
    if getPlayerStorageValue(attacker, LOOP_KEY) == 1 then
        setPlayerStorageValue(attacker, LOOP_KEY, -1)
        return true
    end

    local bonus = tonumber(StatueDonation.getNationDamageBonus()) or 0
    local extra = math.floor(damage * bonus / 100)
    if extra < 1 then
        extra = 1
    end

    setPlayerStorageValue(attacker, LOOP_KEY, 1)
    doTargetCombatHealth(attacker, cid, combat, -extra, -extra, -1)
    return true
end
