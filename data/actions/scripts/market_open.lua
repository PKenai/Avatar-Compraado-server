-- ============================================================================
-- Market Open Action
-- ----------------------------------------------------------------------------
-- Coloque a actionid 50005 em qualquer item/objeto no mapa ou inventario
-- e ao dar "use" nele o Market sera aberto no cliente.
-- ============================================================================

function onUse(cid, item, fromPosition, itemEx, toPosition)
    Market.sendOfferOtclient(cid, 1, "", "all")
    return true
end
