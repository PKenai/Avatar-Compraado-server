-- ============================================================
--  ARQUIVO DE CODIGOS - AVATAR
--  Atualizado pelo gerador_codigos.bat (pasta "Controles de uso").
--
--  O servidor rele este arquivo do disco a CADA resgate de codigo
--  (CodeRedeem.loadCodes), entao codigos novos gravados aqui entram
--  em vigor imediatamente - SEM reiniciar o servidor.
--
--  Formato de cada codigo:
--    CodeRedeemData["CODIGO"] = {
--      storage = <numero unico>,                 -- obrigatorio
--      expire  = <timestamp unix>,               -- opcional (0 = nunca expira)
--      maxUses = <numero>,                       -- opcional (limite de resgates; 0 = sem limite)
--      items   = { {itemid, quantidade}, ... },  -- obrigatorio
--      message = "texto custom"                  -- opcional
--    }
--
--  Contador de usos (para maxUses) fica em codes_used.lua e e
--  incrementado pelo servidor a cada resgate com limite de uso.
--
--  Obs: o servidor dobra acentos, entao digitar PROMOCAO ou
--  PROMOCAO da no mesmo (com ou sem acento).
-- ============================================================

CodeRedeemData = {}



