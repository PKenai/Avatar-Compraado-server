-- NAO entrega mais arma classica (crystalline sword/club/axe). Arma classica
-- tem ataque E defesa: entraria nos dois lados do see-saw de uma vez
-- (bonus de ataque nas magias + corte de defesa no PvP, ver sources/combat.cpp).
function onUse(cid, item, fromPosition, itemEx, toPosition)
	if getPlayerStorageValue(cid, item.uniqueid) == -1 then
		setPlayerStorageValue(cid, item.uniqueid, 1)
	end
	return doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, getLangString(cid, "The chest is empty.", "Esse chest está vazio."))
end