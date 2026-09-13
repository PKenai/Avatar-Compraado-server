local MyLocal = {}
MyLocal.players = {}

local function sendAllCheckFunctions(cid)
  sendInitialItens(cid)
  sendBackupToPlayer(cid)
  sendAllConfigsToClient(cid)
  setPlayerStorageValue(cid, "getAwnserAntiBot", -1) --antiBot System
  setPlayerStorageValue(cid, "currentCid", cid)
  MyLocal.players[cid] = getPlayerGUID(cid)
end

-- Limpa o cache do player no logout: sem isso a tabela cresce com todo cid que
-- ja' passou pelo servidor desde o boot.
function flySystemCleanup(cid)
  MyLocal.players[cid] = nil
  return true
end

function onThink(cid, interval)
  if not isPlayer(cid) then
    return true
  end

  -- O cid e' reciclado pelo servidor. Guardando o GUID junto, um player novo
  -- que herde o cid de outro nao cai no "ja' enviei": antes disso o if externo
  -- curto-circuitava e o player ficava sem itens iniciais e sem configs.
  if MyLocal.players[cid] ~= getPlayerGUID(cid) then
      if getPlayerStorageValue(cid, "currentCid") ~= cid then
        sendAllCheckFunctions(cid)
      else
        MyLocal.players[cid] = getPlayerGUID(cid)
      end
    end

    -- isSqmVoid/getSqmFloorId estao em data/lib/050-function.lua e varrem o
    -- stack do sqm em vez de olhar so o stackpos 0. Isso importa porque, quando
    -- o player esta EM CIMA do piso falso (460) das dobras, o stackpos 0 devolve
    -- a propria criatura (itemid 1) - era por isso que o Water Surf conseguia
    -- "segurar" o player no ar para sempre mesmo sem nada embaixo dele.
    local currentPos = getThingPos(cid)

    if isSqmVoid(currentPos) then
        -- Sem chao de verdade (nenhum chao ou so o piso falso): esta no ar.
        -- O doPlayerDown desce um andar por vez, criando os pisos falsos que
        -- precisar, ate achar chao de verdade - e quando acha, ele mesmo limpa
        -- o flag playerOnAir.
        setPlayerStorageValue(cid, "playerOnAir", 1)
        doPlayerDown(cid)
    elseif getPlayerStorageValue(cid, "playerOnAir") == 1 then
        -- Pisou em chao de verdade: nao esta mais no ar.
        setPlayerStorageValue(cid, "playerOnAir", -1)
    end

    return true
end
