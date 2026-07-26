function onUse(cid, item, fromPosition, itemEx, toPosition)
   if isInArray({0, 65535}, toPosition.x) then
       return doPlayerSendCancel(cid, "Desculpe, nao e possivel.")
   elseif getTileItemById(toPosition, 2555).uid == 0 then
       return doPlayerSendCancel(cid, "Voce deve adicionar os ingredientes sobre a bigorna!.")
   end

   local obj = RecipeFromPosition(toPosition)
   if obj then
       obj:forge(cid, toPosition)
       if _FORGESYSTEM.useSkill == true then addForgeTry(cid) end
   else
       doPlayerSendCancel(cid, _FORGESYSTEM.prompt.invalidRecipe)
   end
   return true
end