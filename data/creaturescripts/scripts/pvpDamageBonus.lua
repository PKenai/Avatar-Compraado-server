--[[
================================================================================
  PVP DAMAGE BONUS - +50% de dano quando PLAYER acerta PLAYER
--------------------------------------------------------------------------------
  Registrado como creatureevent "statschange" (PvpDamageBonus) e registrado no
  login junto dos outros eventos do personagem (loginLogout/login.lua).

  Regra: se quem causou o dano E' um PLAYER e quem levou tambem, esse dano ganha
  PVP_DAMAGE_BONUS_PERCENT% a mais. Todo o resto fica intacto: monstro -> player,
  player -> monstro, summon batendo e dano proprio (campo/exaustao/reflexo) NAO
  ganham nada.

  COMO O BONUS E' APLICADO
  - O extra e' somado via doTargetCombatHealth, atribuido ao MESMO atacante, entao
    continua contando normalmente para exp, loot, frag e medidor de dano. NAO
    cancelamos e reenviamos o dano original: ele ja' passou por defesa/armadura e
    ja' consumiu mana shield, e reenviar poderia perder o hit (alvo morto, andou,
    saiu de alcance) - aqui, no pior caso, o player so' perde os 50% extras.
  - A guarda de reentrada (storage no atacante) impede que o proprio dano extra
    dispare este script de novo e vire bola de neve. Mesma ideia do
    statueBonus.lua / reflect.lua / proficiencyCombat.lua.

  LIMITES CONHECIDOS (propositais)
  - O valor que chega aqui e' o dano JA' reduzido por defesa/armadura e JA'
    limitado pela vida restante do alvo, entao o "50%" e' sobre o dano final.
  - Com mana shield, a parte absorvida pela mana nao entra no calculo (ela sai
    por outro caminho, antes deste evento) - so' a parte que foi na vida ganha
    o bonus.
  - O extra aparece como um segundo hit na tela (dois numeros no mesmo instante).

  PARA AJUSTAR O VALOR: mexa em PVP_DAMAGE_BONUS_PERCENT abaixo (50 = +50%).
  Pra desligar sem apagar nada: ponha 0.
================================================================================
]]

local PVP_DAMAGE_BONUS_PERCENT = 50
local LOOP_KEY = "pvpDamageBonusLoop"

function onStatsChange(cid, attacker, statType, combat, value)
    if statType ~= STATSCHANGE_HEALTHLOSS then
        return true
    end

    -- so' PvP: player batendo em player
    if not isPlayer(attacker) or not isPlayer(cid) then
        return true
    end
    if cid == attacker then
        return true -- dano proprio nao conta
    end

    -- reentrada: este e' o dano extra que nos mesmos mandamos
    if getPlayerStorageValue(attacker, LOOP_KEY) == 1 then
        setPlayerStorageValue(attacker, LOOP_KEY, -1)
        return true
    end

    if PVP_DAMAGE_BONUS_PERCENT <= 0 then
        return true
    end

    local damage = math.abs(tonumber(value) or 0)
    if damage <= 0 then
        return true
    end

    local extra = math.floor(damage * PVP_DAMAGE_BONUS_PERCENT / 100)
    if extra < 1 then
        return true
    end

    setPlayerStorageValue(attacker, LOOP_KEY, 1)
    doTargetCombatHealth(attacker, cid, combat, -extra, -extra, -1)
    setPlayerStorageValue(attacker, LOOP_KEY, -1)
    return true
end
