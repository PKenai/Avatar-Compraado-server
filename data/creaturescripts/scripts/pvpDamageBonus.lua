--[[
================================================================================
  PVP DAMAGE BONUS - desfaz o corte que o MOTOR aplica em player x player
--------------------------------------------------------------------------------
  Registrado como creatureevent "statschange" (PvpDamageBonus) e registrado no
  login junto dos outros eventos do personagem (loginLogout/login.lua).

  O PROBLEMA QUE ESTE SCRIPT RESOLVE
  O motor divide por 2 TODO dano de player em player (Combat::CombatHealthFunc em
  sources/combat.cpp; a mesma regra esta' em ConditionDamage, condition.cpp).
  Sem este script o PvP valeria METADE do PvE para as 4 vocacoes.

  COMO O VALOR FINAL E' CALCULADO (importante)
  - O numero que chega aqui e' o dano JA' cortado pela metade pelo motor.
  - O extra que mandamos por doTargetCombatHealth VOLTA pelo mesmo caminho e e'
    cortado de novo. Sendo d o dano que chegou e P o percentual abaixo:
        total = d + (d * P/100) / 2
  - P = 200 -> total = 2d = exatamente o dano cru do PvE. E' o valor de hoje:
    PvP normal, sem nerf.
  - P = 50 (valor antigo) -> total = 1,25d = so' 62,5% do PvE. O "+50%" do
    titulo nunca chegou ao jogo: metade dele era comido pelo proprio corte.

  Regra: se quem causou o dano E' um PLAYER e quem levou tambem, esse dano ganha
  PVP_DAMAGE_BONUS_PERCENT% a mais. Todo o resto fica intacto: monstro -> player,
  player -> monstro, summon batendo e dano proprio (campo/exaustao/reflexo) NAO
  ganham nada.

  DETALHES DA APLICACAO
  - O extra e' somado via doTargetCombatHealth, atribuido ao MESMO atacante, entao
    continua contando normalmente para exp, loot, frag e medidor de dano. NAO
    cancelamos e reenviamos o dano original: ele ja' passou por defesa/armadura e
    ja' consumiu mana shield, e reenviar poderia perder o hit (alvo morto, andou,
    saiu de alcance) - aqui, no pior caso, o player so' perde o dano extra.
  - A guarda de reentrada (storage no atacante) impede que o proprio dano extra
    dispare este script de novo e vire bola de neve. Mesma ideia do
    statueBonus.lua / reflect.lua / proficiencyCombat.lua.
  - A trava compartilhada CombatRecursionGuard (data/lib/combatRecursionGuard.lua)
    marca ESTE dano extra como "dano de script": a reducao do
    imuneable/proficiency e a reflexao do reflect nao voltam a mexer nele. Era
    esse ping-pong que estourava o limite de 21 chamadas Lua do motor. O
    percentual abaixo continua valendo integralmente no hit original.
  - Alvo de SKULL PRETA fica de fora: nesse caso o motor nao divide por 2, e
    somar o extra daria dano dobrado. E' a mesma condicao que o motor usa.

  LIMITES CONHECIDOS (propositais)
  - O extra passa por defesa/armadura uma SEGUNDA vez, entao contra alvo de
    armadura alta o total fica um pouco ABAIXO do dano de PvE (armadura e'
    reducao plana e morde duas vezes). Exatidao total so' tirando o /2 do motor -
    ver a nota do fim.
  - Com mana shield, a parte absorvida pela mana nao entra no calculo (ela sai
    por outro caminho, antes deste evento) - so' a parte que foi na vida ganha
    o bonus.
  - O extra aparece como um segundo hit na tela (dois numeros no mesmo instante).

  PARA AJUSTAR O VALOR: mexa em PVP_DAMAGE_BONUS_PERCENT abaixo.
    200 = PvP igual ao PvE (ATUAL)    100 = PvP a 75% do PvE
     50 = PvP a 62,5% do PvE           0 = desliga (PvP volta a METADE do PvE)

  SE UM DIA O /2 SAIR DO MOTOR: apague os cortes de Combat::CombatHealthFunc
  (sources/combat.cpp) e de ConditionDamage::doDamage (sources/condition.cpp) e,
  NO MESMO COMMIT, ponha este percentual em 0 - senao o PvP vira 1,5x o PvE.
  Nesse caminho vale revisar tambem os "*2" do imuneable.lua, que existem hoje
  justamente para compensar aquele /2.
================================================================================
]]

local PVP_DAMAGE_BONUS_PERCENT = 200
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

    -- alvo de skull preta: o motor NAO divide por 2 nesse caso, entao somar o
    -- extra daria dano dobrado (mesma condicao do Combat::CombatHealthFunc)
    if getCreatureSkullType(cid) == SKULL_BLACK then
        return true
    end

    -- O extra enviado no fim deste script vai dentro de CombatRecursionGuard.run():
    -- a passagem fica marcada como "dano de script" e nem a reducao
    -- (imuneable/proficiency) nem a reflexao (reflect) voltam a mexer nela.
    -- Era esse ping-pong que estourava o limite de 21 chamadas Lua do motor.
    -- Ver data/lib/combatRecursionGuard.lua.

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
    CombatRecursionGuard.run(doTargetCombatHealth, attacker, cid, combat, -extra, -extra, -1)
    setPlayerStorageValue(attacker, LOOP_KEY, -1)
    return true
end
