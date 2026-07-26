local externalCidSnake = getStorage("cidSnakeGame")

local function checkStillInAir(cid, oldOnAir, oldCantDown)
	if not isCreature(cid) then return false end
    local newPos = getCreaturePosition(cid)
	if getPlayerStorageValue(cid, "playerOnAir") == -1 then
		local item = getThingfromPos({x=newPos.x,y=newPos.y,z=newPos.z,stackpos=0})
		if item.itemid == 1 or item.itemid == 460 or item.itemid == 0 then
			setPlayerStorageValue(cid, "playerOnAir", oldOnAir)
			setPlayerStorageValue(cid, "playerCantDown", oldCantDown)
		end
	end
end

function onMove(cid, dir)
    local newPos = getPosByDir(getCreaturePosition(cid), dir, 1)
  if getPlayerStorageValue(cid, "playerOnAir") == 1 then
 --   local newPos = getPosByDir(getCreaturePosition(cid), dir, 1)

    if isWaterBlock({x=newPos.x,y=newPos.y,z=7,stackpos=0}) then
      return false
    end

    local item = getThingfromPos({x=newPos.x,y=newPos.y,z=newPos.z,stackpos=0})

    if item.itemid == 1 or item.itemid == 460 or item.itemid == 0 then
      if (getPlayerCanWalk({player = cid, position = {x=newPos.x,y=newPos.y,z=newPos.z+1}, checkPZ = false, checkHouse = true}) == false and hasSqm({x=newPos.x, y=newPos.y, z=newPos.z+1}) == true) or getPlayerStorageValue(cid, "playerCantDown") == 1 then
                doCreateTile(460, newPos)
      else
          doCreateTile(460, newPos)
          addEvent(doPlayerDown, 100, cid, true)
      end
    elseif not (isPlayerPzLocked(cid) and getTileInfo(newPos).protection) then
		-- todo acho que aqui tb ta entrando quando nao consegue dar move pro sqm (pz locked indo pra pz)
		-- ocasionando em bugs como o earth podendo usar dobras, novo jump etc estando no ar
      --doRemoveCondition(cid, CONDITION_OUTFIT)
	  addEvent(checkStillInAir, 30, cid, getPlayerStorageValue(cid, "playerOnAir"), getPlayerStorageValue(cid, "playerCantDown"))
      setPlayerStorageValue(cid, "playerOnAir", -1)
      setPlayerStorageValue(cid, "playerCantDown", -1)
    end
  end
  --if getTileInfo(newPos).protection then 
--	 dismountPlayer(cid)
 -- end 
  return true
end


event = {
  logout = function(cid)
    local pos = getThingPos(cid)
    setPlayerStorageValue(cid, "onMoveFlyPosX", pos.x)
    setPlayerStorageValue(cid, "onMoveFlyPosY", pos.y)
    setPlayerStorageValue(cid, "onMoveFlyPosZ", pos.z)
  end,
  login = function(cid)
    local oldPos = {x=getPlayerStorageValue(cid, "onMoveFlyPosX"), y=getPlayerStorageValue(cid, "onMoveFlyPosY"), z=getPlayerStorageValue(cid, "onMoveFlyPosZ")}
    local currentPos = getThingPos(cid)

    if getPlayerStorageValue(cid, "playerOnAir") == 1 and not comparePoses(currentPos, oldPos) then
      if getPlayerStorageValue(cid, "playerCantDown") == 1 then
        if getPlayerSex(cid) == 0 then
                doAddCondition(cid, conditionVoarFemale)
            else
                doAddCondition(cid, conditionVoarMale)
            end
          end
      doCreateTile(460, oldPos)
      doTeleportThing(cid, oldPos)
    end

    if not hasSqm(currentPos) then
           doCreateTile(460, oldPos)
         doTeleportThing(cid, oldPos)
      end
  end,
  
  death = function(cid)
    setPlayerStorageValue(cid, "playerOnAir", -1)
  end
}