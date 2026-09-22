--[[
  ManaRegen -- ganchos do creaturescript (regen de mana passiva).

  O mecanismo em si esta' em data/lib/manaRegen.lua. Aqui ficam so' os ganchos:

    <event type="login" name="ManaRegenLogin" .../>  -> onLogin: aplica a regen
    <event type="think" name="ManaRegenRefresh" .../> -> onThink: reaplica

  Por que os dois: o onLogin garante a regen no instante em que o char entra
  (a condicao nao e' salva no banco, entao sem isso ela so' apareceria no
  proximo tick). O onThink e' rede de seguranca -- se algum sistema apagar as
  condicoes do player, a regen volta sozinha em poucos segundos.

  O motor nao tem hook de "condition removida", entao a checagem e' por tempo:
  um contador por cid (um numero por char visto desde o boot; irrelevante em
  memoria) que dispara o REFRESH_MS da lib.
]]--

local acc = {} -- cid -> ms acumulados desde a ultima reaplicacao

function onLogin(cid)
  ManaRegen.apply(cid)

  -- registra o proprio think (o evento existe no XML, mas precisa ser
  -- registrado por player -- mesmo padrao dos outros eventos deste fork)
  registerCreatureEvent(cid, "ManaRegenRefresh")

  return true
end

function onThink(cid, interval)
  acc[cid] = (acc[cid] or 0) + (interval or 1000)

  if acc[cid] >= ManaRegen.REFRESH_MS then
    acc[cid] = 0
    ManaRegen.apply(cid)
  end

  return true
end
