function onMount(cid, mountId)
	if getCreatureCondition(cid, CONDITION_OUTFIT) then
		return false
	end
	return true
end 