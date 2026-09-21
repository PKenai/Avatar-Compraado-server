--[[
================================================================================
  STATUE DONATION - use da estatua
--------------------------------------------------------------------------------
  A estatua e' o ITEMID 19335 (registrado em actions.xml). Qualquer item com o
  ACTIONID 50030 tambem abre. Toda a logica vive em data/lib/statueDonation.lua -
  este arquivo so' liga o "use" do item na janela do client.

  Nao precisa de Unique ID nem de Action ID: basta ser o item 19335.
================================================================================
]]

function onUse(cid, item, fromPosition, itemEx, toPosition)
    if type(StatueDonation) ~= "table" then
        doPlayerSendCancel(cid, "The statue is silent.")
        return true
    end

    return StatueDonation.onUseStatue(cid, item, fromPosition, itemEx, toPosition)
end
