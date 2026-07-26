local APPA_CLOUD_OPCODE = 6 -- ExtendedIds.MapShader

function onStepIn(cid, item, position, fromPosition)
	if not isPlayer(cid) then
		return true
	end
	doSendPlayerExtendedOpcode(cid, APPA_CLOUD_OPCODE, "map_cloudy")
	return true
end

function onStepOut(cid, item, position, fromPosition)
	if not isPlayer(cid) then
		return true
	end
	doSendPlayerExtendedOpcode(cid, APPA_CLOUD_OPCODE, "")
	return true
end
