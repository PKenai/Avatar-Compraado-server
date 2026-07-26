Player = {}

function Player:new(cid)
    local infos = {uid = cid}
    setmetatable(infos, {__index = self})   
    return infos 
end

function setPlayer(cid)
    return Player:new(cid)
end

function Player:getCid()
    return self.uid
end

function Player:exist()
    return isCreature(self.uid)
end

function Player:getName()
    return getCreatureName(self.uid)
end

function Player:setCanMove(state)
    return doCreatureSetNoMove(self.uid, state)
end

function Player:getMaxHealth()
    return getCreatureMaxHealth(self.uid)
end

function Player:getHealth()
    return getCreatureHealth(self.uid)
end

--[[function Player:isWalkable(pos, ignore)
    if self:exist() then
        if getThingfromPos({x=pos.x,y=pos.y,z=pos.z,stackpos=0}).itemid == 0 and not ignore then 
            return false 
        elseif ignore then
            doCreateTile(460, pos)
        end

        local possibleCreature = getTopCreature(pos)
        if possibleCreature.uid > 0 and possibleCreature.uid ~= self.uid then 
            return false 
        end
        
        if getTileInfo(pos).protection then 
            return false
        end

        if doTileQueryAdd(self.uid, pos) == 1 then
            return false
        end
        
        return true
    end
end--]]