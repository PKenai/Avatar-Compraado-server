-- ============================================================================
-- Market Open Action
-- ----------------------------------------------------------------------------
-- Coloque a actionid 50005 em qualquer item/objeto no mapa ou inventario
-- e ao dar "use" nele o Market sera aberto no cliente.
-- ============================================================================

function onUse(cid, item, fromPosition, itemEx, toPosition)
    -- sendOpenOtclient manda o prefixo "open>", que e' o que faz o cliente
    -- abrir a janela (uma resposta normal de lista nao abre mais nada).
    Market.sendOpenOtclient(cid)
    return true
end
