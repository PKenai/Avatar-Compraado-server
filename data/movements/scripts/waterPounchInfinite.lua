-- ============================================================
-- EQUIP: Agua milagrosa do oasis (ID 18999)
-- Item infinito de agua - sempre reporta 100% ao equipar
-- ============================================================

function onEquip(cid, item, slot)
  if item.uid > 0 then
    -- Sempre envia 100% de agua pro client
    sendWaterPounchToClient(cid, 100)
  end
  return true
end
