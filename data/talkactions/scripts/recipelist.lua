function onSay(cid, words, param, channel)
   local text = "Tudo que um Ferreiro deve saber:\n"
   local n = 1
   for itemid, parameter in pairs(_FORGERECIPES) do
       text = text .. "\n#".. n .." Receita para fazer um ".. getItemNameById(itemid) .."\n\n     Voce vai precisar:\n\n"
       for i = 1, #parameter.items do
           text = text .. "          ".. parameter.items[i][2] .." un. of ".. getItemNameById(parameter.items[i][1]) .."\n"
       end
       if _FORGESYSTEM.useSkill == true then text = text .."\n".. (getForgeLevel(cid) >= parameter.skill and "     Voce pode" or "     Voce ainda pode't") .." Fazer esse item.\n\n" end
       n = n + 1
   end
   return doShowTextDialog(cid, 2555, text)
end