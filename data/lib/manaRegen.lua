--[[
  ManaRegen -- regeneracao de mana passiva, SEMPRE ativa, para qualquer vocacao.

  POR QUE ISSO EXISTE
  Este motor nasce sem regen passiva: quem cria a CONDITION_REGENERATION e' o
  doPlayerFeed (comida, data/actions/scripts/foods/*.lua), com os valores da
  vocacao (data/XML/vocations.xml -> gainmanaamount / gainmanaticks) e duracao
  finita (food * 3000 ms). Sem comer, o char nao regenera nada.

  O QUE ESTA LIB FAZ
  Mantem uma CONDITION_REGENERATION propria, com duracao INFINITA, que da'
  5 de mana a cada 2s para qualquer vocacao, alimentado ou nao.

  DETALHES QUE NAO PODEM SER ESQUECIDOS (cada um foi conferido no C++)

  * subId fixo (SUBID) porque o motor casa condicoes por type + id + subId
    (Creature::getCondition, creature.cpp). A condicao de comida e'
    CONDITIONID_DEFAULT + subId 0, entao as duas convivem sem se tocar.
    Isso importa: se caissem no MESMO slot, o
    ConditionRegeneration::addCondition (condition.cpp:722) SOBRESCREVE os
    params do que ja' existe -- e como esta lib nao define HP, ela apagaria o
    regen de vida que a comida da'.

  * TICKS = -1 (infinita). Duracao positiva jogaria a condicao no grupo
    "persistent" (condition.h:151) e o removeConditions(CONDITIONEND_DEATH)
    (player.cpp, chamado na morte) a apagaria. Com -1 ela sobrevive a morte
    e ao doRemoveConditions(cid, true) do swimming.lua.

  * Quem limita o tick e' o proprio motor: ConditionRegeneration::
    executeCondition so' regenera fora da zona de protecao (ZONE_PROTECTION),
    entao PZ continua sem regen, igual a comida.

  * vocations.xml esta com gainmanaamount="0" DE PROPOSITO: a mana agora vem
    so' daqui, senao o char alimentado somaria os 5/2s da comida com estes
    5/2s e regeneraria 10/2s. O gainmana (mana ganha por level) segue intacto.

  PARA AJUSTAR A REGEN: mude MANA / TICK_MS aqui e reinicie o servidor.
]]--

ManaRegen = {
  MANA    = 5,      -- mana por tick
  TICK_MS = 2000,   -- 1 tick a cada 2s  =>  5 de mana a cada 2s
  SUBID   = 77,     -- slot proprio da regen passiva (0 = condicao da comida)

  -- Rede de seguranca: no onThink a lib reaplica a condicao de tempos em
  -- tempos. Como a condicao e' infinita e reaplicar e' idempotente (mesmo
  -- type + id + subId => mesmos ticks e mesmos gains), isso so' serve para
  -- restaurar a regen se algum sistema futuro apagar as condicoes do player.
  REFRESH_MS = 10000
}

-- Aplica (ou reaplica, sem efeito colateral) a regen passiva no player.
function ManaRegen.apply(cid)
  if not isPlayer(cid) then
    return false
  end

  local condition = createConditionObject(CONDITION_REGENERATION)
  if not condition then
    return false
  end

  setConditionParam(condition, CONDITION_PARAM_SUBID, ManaRegen.SUBID)
  setConditionParam(condition, CONDITION_PARAM_TICKS, -1)
  setConditionParam(condition, CONDITION_PARAM_MANAGAIN, ManaRegen.MANA)
  setConditionParam(condition, CONDITION_PARAM_MANATICKS, ManaRegen.TICK_MS)

  -- Aplica so' mana: nenhum param de HP e' setado, entao o regen de vida
  -- continua sendo o da comida (5 hp/1s enquanto alimentado).
  doAddCondition(cid, condition)

  return true
end
