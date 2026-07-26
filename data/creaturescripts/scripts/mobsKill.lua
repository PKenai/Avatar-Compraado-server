function onDeath(cid)
if isMonster(cid) then
	        local posicao = getThingPos(cid)
			local stoneId = 8046
		doCreateItem(stoneId, 1, posicao)
        doSendMagicEffect({x=posicao.x, y=posicao.y+2, z=posicao.z}, 171)
        addEvent(removeTileItemById, 1000, posicao, stoneId)
end
return true
end