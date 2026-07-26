local MyLocal = {}
MyLocal.players = {}

local function sendMagicEff(cid)
   if MyLocal.players[cid] == nil or not isPlayer(cid) then
      return true
   end
   local pos = getThingPos(cid)

   if not comparePoses(pos, MyLocal.players[cid]) then
      return true
   end

   pos.stackpos = 0
   if getThingfromPos(pos).itemid ~= 460 and getThingfromPos(pos).itemid ~= 1 then
      return true
   end

   pos.x = pos.x+1

   doSendMagicEffect(pos, 67)
   addEvent(sendMagicEff, 500, cid)
end

local function removeTable(cid)
   if isCreature(cid) then
      MyLocal.players[cid] = nil
      doPlayerAddExaust(cid, "air", "jump", airExausted.jump)
   end
end

function onCastSpell(cid, var)
         if not isPlayer(cid)  then
               return false
         end

         if getSpellCancels(cid, "air") == true then
               return false
         end

         if getPlayerExaust(cid, "air", "jump") == false then
               return false
         end

         if MyLocal.players[cid] == nil then
               workAllCdAndAndPrevCd(cid, "air", "jump", 4000, 1)
               if getPlayerHasStun(cid) then
                  removeTable(cid)
                  return true
               end

               local position = getPlayerPosition(cid)   
				dismountPlayer(cid)
               doPlayerAddUp(cid, false)
               MyLocal.players[cid] = {x=position.x,y=position.y,z=position.z-1}
               sendMagicEff(cid)
               doCreateItem(12966, 1, position)
               addEvent(removeTileItemById, 3000, position, 12966)  
               addEvent(removeTable, 4000, cid) 
               return true
         else
            doPlayerSendCancelEf(cid, "You're already using this fold.")
            return false
         end
end