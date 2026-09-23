-- ============================================================================
--  COMBAT RECURSION GUARD
--  (anti "Call stack overflow" nos handlers de statschange)
-- ----------------------------------------------------------------------------
--  O PROBLEMA
--  O motor limita a 21 o numero de execucoes Lua SIMULTANEAS (reserveEnv /
--  releaseEnv em sources/luascript.h). Passando disso ele imprime
--  "[Error - <guarda>] Call stack overflow." e PULA o evento - magia, movement,
--  NPC etc. deixam de rodar naquele instante.
--
--  Cinco scripts deste datapack causam dano de DENTRO do proprio onStatsChange:
--
--      imuneable.lua         reducao de dano, reflexao, armor chest/set
--      proficiencyCombat.lua reducao de dano (proficiency + talento de armadura)
--      statueBonus.lua       +5% da nacao contra monstro
--      pvpDamageBonus.lua    +200% no PvP
--      reflect.lua           dano refletido
--
--  doTargetCombatHealth/doCombat/doCreatureAddHealth sao SINCRONOS: o dano novo
--  dispara um statschange completo DENTRO do handler que ainda esta rodando, ou
--  seja, +1 nivel de aninhamento por disparo. Cada script so' protegia a propria
--  reentrada (flag em storage propria) e, como essas flags sao limpas dentro da
--  passagem aninhada, dois scripts diferentes podiam se alimentar em ping-pong:
--
--      reduz o dano  ->  o dano reduzido leva o bonus de +X%  ->
--      o dano com bonus e' reduzido de novo  ->  ...  ->  estoura o limite
--
--  SOLUCAO
--  Uma trava unica, compartilhada pelos cinco: todo dano enviado dentro de
--  CombatRecursionGuard.run(...) marca a passagem como "dano de script", e
--  nenhum handler volta a gerar dano em cima dela. A cadeia fica com 1 nivel.
--
--  COMO USAR
--      -- 1) nao reprocessar dano gerado por script
--      if CombatRecursionGuard.isInside() then return true end
--
--      -- 2) marcar o dano que ESTE script gera
--      CombatRecursionGuard.run(doTargetCombatHealth, atacante, alvo, combat, -v, -v, -1)
--
--  EFEITO NO JOGO
--  O hit original continua passando por todos os handlers normalmente. O que
--  deixa de acontecer e' o empilhamento entre eles (o +5% da nacao nao incide
--  sobre o dano ja' reduzido pelo proficiency, por exemplo) - que era justamente
--  o que alimentava a recursao.
--
--  O contador e' devolvido mesmo se a chamada estourar erro (o erro e' repassado).
-- ============================================================================

CombatRecursionGuard = CombatRecursionGuard or { depth = 0 }

local guard = CombatRecursionGuard

-- true quando estamos DENTRO de um dano gerado por script.
function guard.isInside()
    return guard.depth > 0
end

-- Executa fn(...) marcando a passagem como dano de script.
function guard.run(fn, ...)
    guard.depth = guard.depth + 1
    local ok, err = pcall(fn, ...)
    guard.depth = guard.depth - 1
    if not ok then
        error(err)
    end
end

-- Valvula de escape: zera a trava (usar so' se algum dia ela ficar presa em 1
-- por um bug de script).
function guard.reset()
    guard.depth = 0
end
