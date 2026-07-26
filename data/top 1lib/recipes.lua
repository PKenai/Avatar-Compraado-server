


----------------------------------------

-----** TUTORIAL DE CONFIGURAÇÃO **-----

----------------------------------------


--[[


	O 'ADVANCED FORGE SYSTEM' é muito fácil e intuitivo de configurar, você só precisa chamar

	a função RecipeHandler:new(...), sendo que você já configurar os atributos da receita nela

	ou usar outras funções para isso.


	Por exemplo, quero criar uma Magic Sword que precise de 100 Gold Nuggets.


	RecipeHandler:new(2400, {{2157, 100}})?????


	Ou então


	Magic_Sword = RecipeHandler:new()

	Magic_Sword:setItem(2400)

	Magic_Sword:setRecipe({2157, 100})


	Funções do Sistema:


	RecipeHandler:new(itemtype, items, level, maglevel, skills) --> Cria uma nova instância de forja.

	RecipeHandler:setItem(itemtype) --> Atribui um certo itemid como resultado da receita.

	RecipeHandler:setRecipe(recipe) --> Atribui uma receita.

	RecipeHandler:setRecipeItem(itemid, amount) --> Adiciona um itemid e sua quantidade a receita.

	RecipeHandler:setSkill(skillid, value) --> Atribui um valor necessário de uma certa skill para poder criar a receita.

	RecipeHandler:setLevel(value) --> Atribui o level necessário para criar uma receita.

	RecipeHandler:setMagLevel(value) --> Atribui o magic level necessário para criar uma receita.


]]--



--[[	

	Este é um exemplo de receita usando algumas funções.


	É uma Magic Sword (ITEMID: 2400) que precisa de 100 Gold Nuggets (ITEMID: 2157),

	além disso, o personagem que tentar forjar, precisa ter Level 100 e Sword Fighting 50.

]]--


Recipes = {}

--[[
magicsword = RecipeHandler:new()
magicsword:setItem(2400)
magicsword:setRecipeItem(2157, 100)
magicsword:setLevel(1)
magicsword:setSkill(2, 1)
]]--

--RecipeHandler:new(13689, {{2157, 50},{2691, 1}})

incanhelmet = RecipeHandler:new()
incanhelmet: setItem(13689)
incanhelmet: setRecipeItem (2157, 10)
incanhelmet: setRecipeItem (9971, 10)
incanhelmet: setLevel(10)

hunterhelmet = RecipeHandler:new()
hunterhelmet: setItem(13712)
hunterhelmet: setRecipeItem (2157, 1)
hunterhelmet: setRecipeItem (9971, 1)
hunterhelmet: setLevel(10)

aquazarhelmet = RecipeHandler:new()
aquazarhelmet: setItem(13748)
aquazarhelmet: setRecipeItem (2157, 2)
aquazarhelmet: setRecipeItem (9971, 2)
aquazarhelmet: setLevel(10)

coroakhelmet = RecipeHandler:new()
coroakhelmet: setItem(13701)
coroakhelmet: setRecipeItem (2157, 3)
coroakhelmet: setRecipeItem (9971, 3)
coroakhelmet: setLevel(10)

illusionhat = RecipeHandler:new()
illusionhat: setItem(13657)
illusionhat: setRecipeItem (2157, 4)
illusionhat: setRecipeItem (9971, 4)
illusionhat: setLevel(10)

falconhelmet = RecipeHandler:new()
falconhelmet: setItem(13675)
falconhelmet: setRecipeItem (2157, 5)
falconhelmet: setRecipeItem (9971, 5)
falconhelmet: setLevel(10)

ancientfalmer = RecipeHandler:new()
ancientfalmer: setItem(13694)
ancientfalmer: setRecipeItem (2157, 6)
ancientfalmer: setRecipeItem (9971, 6)
ancientfalmer: setLevel(10)

benemoldhelmet = RecipeHandler:new()
benemoldhelmet: setItem(13735)
benemoldhelmet: setRecipeItem (2157, 7)
benemoldhelmet: setRecipeItem (9971, 7)
benemoldhelmet: setLevel(10)

dominathelmet = RecipeHandler:new()
dominathelmet: setItem(13636)
dominathelmet: setRecipeItem (2157, 8)
dominathelmet: setRecipeItem (9971, 8)
dominathelmet: setLevel(10)

deadrichat = RecipeHandler:new()
deadrichat: setItem(13721)
deadrichat: setRecipeItem (2157, 9)
deadrichat: setRecipeItem (9971, 9)
deadrichat: setLevel(10)

solarhelmet = RecipeHandler:new()
solarhelmet: setItem(13416)
solarhelmet: setRecipeItem (2157, 11)
solarhelmet: setRecipeItem (9971, 11)
solarhelmet: setLevel(10)

imperialhelmet = RecipeHandler:new()
imperialhelmet: setItem(13706)
imperialhelmet: setRecipeItem (2157, 12)
imperialhelmet: setRecipeItem (9971, 12)
imperialhelmet: setLevel(10)

eruptionhelmet = RecipeHandler:new()
eruptionhelmet: setItem(13725)
eruptionhelmet: setRecipeItem (2157, 13)
eruptionhelmet: setRecipeItem (9971, 13)
eruptionhelmet: setLevel(10)

crystallinehelmet = RecipeHandler:new()
crystallinehelmet: setItem(13744)
crystallinehelmet: setRecipeItem (2157, 14)
crystallinehelmet: setRecipeItem (9971, 14)
crystallinehelmet: setLevel(10)

infernatgoldhelmet = RecipeHandler:new()
infernatgoldhelmet: setItem(13363)
infernatgoldhelmet: setRecipeItem (2157, 15)
infernatgoldhelmet: setRecipeItem (9971, 15)
infernatgoldhelmet: setLevel(10)















