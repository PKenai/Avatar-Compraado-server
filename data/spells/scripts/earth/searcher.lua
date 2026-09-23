function onCastSpell(cid, var)
    if getPlayerExaust(cid, "earth", "searcher") == false then
        return false
    end

    if not doPlayerAddExaust(cid, "earth", "searcher", earthExausted.searcher) then
        return false
    end

    doShowTextDialog(cid, 1949, getLangString(cid, "Write here the player name que you are looking for.\nDo not forget to delete all the text.", "Escreva aqui o nome do player que você está procurando.\nNão esqueça de apagar todo esse texto."), true)
    return true
end
