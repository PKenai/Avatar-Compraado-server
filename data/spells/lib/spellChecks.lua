--[[
  * Faz todas verificações necessarias para as spells, porém ainda não funciona em spells complexas,
    pois elas precisam fazer varias verificações a parte, para serem tratadas individualmente.
]]--

local function returnElement(spellName)
  return string.explode(spellName, " ")[1]
end

local function returnSpell(spellName)
  return string.explode(spellName, " ")[2]
end

function allSpellChecks(cid, spellName, exaustTime, alreadyStarted)
  local spellElement = returnElement(spellName)

  if alreadyStarted then
    return false
  end

  if getSpellCancels(cid, spellElement) then
        return false
    end

    local spellName = returnSpell(spellName)

    if not getPlayerExaust(cid, spellElement, spellName) then
        return false
    end

    doPlayerAddExaust(cid, spellElement, spellName, exaustTime or 1)

    if getPlayerHasStun(cid) then
        return true
    end

    return "ready"
end