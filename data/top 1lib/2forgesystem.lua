--[[

     Advanced Forge System
     Version 3.0.0


]]--

----------********************----------
----         SYSTEM CONFIG            ----
----------********************----------

--[[
   Adicionar receitas no sistema é extremamente fácil e intuitivo, basta seguir o modelo:

       local _FORGERECIPES = {
           [itemid] = {
               items = {
                   {id, count},
                   {id, count},
                   ...
               }
           }
       }

   Por exemplo, quero adicionar uma receita de um Golden Helmet que irá precisar de 100 Gold Ingots e skill 11, então:

       local _FORGERECIPES = {
           [2400] = {
               items = {
                   {2157, 100}
               },
               skill = 10
           },
           {
           [2457] = {
               items = {
                   {9971, 100}
               },
               skill = 11
           }
       }

   Em hipótese alguma esqueça de colocar uma vírgula no fim da tabelas internas.

]]-- 
_FORGESYSTEM = {
   useMagicEffect = true, -- Mostrar efeitos animados no sistema?
   useSkill = true, -- Usar sistema de skill Forging
   storages = { -- Storages usados no sistema de skill
       level = 99900,
       tries = 99901
   },
   prompt = { -- Mexa aqui apenas se souber o que está fazendo
       invalidRecipe = "This recipe is not valid.",
       needSkill = "You need skill level %L to make this recipe.",
       createdItem = "You have created %a %N."
   }
}

_FORGERECIPES = {
   [13712] = {
       items = {
           {2157, 3},
           {9971, 3}
       },
       skill = 1
   }
}




----------********************----------
----       GENERAL FUNCTIONS        ----
----------********************----------

function RecipeFromPosition(position)
   --[[

       Essa é uma das funções mais importantes da biblioteca, consiste em checar se os itens
       agrupados em uma certa posição são uma receita pré-configurada.

       Caso sim, então a função cria um objeto e retorna ele, caso não ela retorna nulo.

   ]]--
   local ret, match = {}
   local obj = nil

   for itemid, parameter in pairs(_FORGERECIPES) do
       for i = 1, #parameter.items do
           local thing = getTileItemById(position, parameter.items[i][1])
           if thing.uid > 0 and math.max(1, thing.type) >= parameter.items[i][2] then
               table.insert(ret, {thing.itemid, parameter.items[i][2]})
               if i == #parameter.items then
                   match = itemid
                   obj = Recipe:new()
                   obj:setResult(match)
                   obj:setItems(ret)
                   obj:setSkill(parameter.skill)
               end
           else
               ret = {}
               break
           end
       end
       if match then break end
   end
   return obj
end

function getForgeLevel(cid)
   return (getPlayerStorageValue(cid, _FORGESYSTEM.storages.level) <= 0 and 1 or getPlayerStorageValue(cid, _FORGESYSTEM.storages.level))
end

function setForgeLevel(cid, value)
   setPlayerStorageValue(cid, _FORGESYSTEM.storages.level, value)
end

function getForgeTries(cid)
   return getPlayerStorageValue(cid, _FORGESYSTEM.storages.tries)
end

function addForgeTry(cid)
   local level = getForgeLevel(cid)
   local tries = getForgeTries(cid)

   if tries + 1 >= (level + (level + 1) * 2) * 3 then
       doPlayerSendTextMessage(cid, MESSAGE_EVENT_ADVANCE, "You have advanced from level ".. level .." to level ".. level + 1 .." in Forging")
       setForgeLevel(cid, level + 1)
       setPlayerStorageValue(cid, _FORGESYSTEM.storages.tries, 0)
   else
       setPlayerStorageValue(cid, _FORGESYSTEM.storages.tries, tries + 1)
   end
end

----------********************----------
----         MAIN FUNCTIONS            ----
----------********************----------

RecipeList = {}

Recipe = {
   itemid = 0,
   items = {},
   skill = 0
}



function Recipe:new(obj)
   --[[

       - Função responsável pela criação de um novo objeto, em outras palavras,
         uma nova receita de forja.

         'obj' é o único parâmetro, sendo este opcional, de modo que é totalmente valido usar a função assim
         Recipe:new() ou já na forma de uma tabela assim Recipe:new({itemid = itemid, items = {{id, count}, ...}})

   ]]--
   return setmetatable(obj or {}, { __index = self })
end

function Recipe:setResult(id)
   --[[
       -     Responsável por atribuir um itemid como resultado do objeto criado por Recipe:new()
           Sua utilização é dada da seguinte forma:

           Recipe:new():setResult(2400)

           Por exemplo, criei um nova receita e 'setei' o resultado dela como o itemid 2400
   ]]--
   id = id or 0
   self.itemid = id
end

function Recipe:setItems(...)
   --[[

       -    Função que atribui uma receita para o objeto.
           Sua utilização é dada da seguinte forma:

           Recipe:new():setItems({{2157, 100}, {4258, 1}, {1000, 100}, ...})

   ]]--

   self.items = ...
end

function Recipe:setSkill(value)
   --[[

       - Função responsável por setar o skill necessário
       para criar o item da receita.

   ]]--
   self.skill = value
end

function Recipe:addItem(item, count)
   --[[
       -     Adiciona um array na forma {item, count} no index items do objeto.

   ]]--
   if not item or not count then
       return false
   end
   table.insert(self.items, {item, count})
end

function Recipe:forge(cid, position)
   if getForgeLevel(cid) >= self.skill or _FORGESYSTEM.useSkill == false then
       for i = 1, #self.items do
           local thing = getTileItemById(position, self.items[i][1])
           doRemoveItem(thing.uid, self.items[i][2])
       end
       if _FORGESYSTEM.useMagicEffect == true then doSendMagicEffect(position, CONST_ME_MAGIC_GREEN) end
       doCreateItem(self.itemid, position)
       if cid then
           doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, (_FORGESYSTEM.prompt.createdItem:gsub("%%N", getItemNameById(self.itemid)):gsub("%%a", getItemInfo(self.itemid).article)))
       end
   else
       doPlayerSendTextMessage(cid, MESSAGE_STATUS_DEFAULT, (_FORGESYSTEM.prompt.needSkill:gsub("%%L", self.skill)))
       if _FORGESYSTEM.useMagicEffect == true then doSendMagicEffect(position, CONST_ME_POFF) end
       for i = 1, #self.items do
           local thing = getTileItemById(position, self.items[i][1])
           doRemoveItem(thing.uid, self.items[i][2])
           doPlayerAddItem(cid, thing.itemid, self.items[i][2])
       end
   end
   return true
end