local reloadInfo = {
  {RELOAD_ACTIONS, "actions", "action"},
  {RELOAD_CHAT, "chat", "channels"},
  {RELOAD_CONFIG, "config", "configuration"},
  {RELOAD_CREATUREEVENTS, "creatureevents", "creature events", "creaturescripts", "creature scripts", "creatureevent", "creature event", "creature script", "creaturescript", "creature"},
  {RELOAD_GAMESERVERS, "gameservers", "game servers", "servers"},
  {RELOAD_GLOBALEVENTS, "globalevents", "global events", "globalevent", "global event", "global"},
  {RELOAD_GROUPS, "groups", "playergroups", "group"},
  {RELOAD_HIGHSCORES, "highscores", "scores", "highscore", "score"},
  {RELOAD_ITEMS, "items", "item"},
  {RELOAD_MONSTERS, "monsters", "monster"},
  {RELOAD_MOUNTS, "mounts", "mount"},
  {RELOAD_AURAS, "auras", "aura"},
  {RELOAD_WINGS, "wings", "wing"},
  {RELOAD_SHADERS, "shaders", "shader"},
  {RELOAD_MOVEEVENTS, "moveevents", "move events", "movements", "move", "movement"},
  {RELOAD_NPCS, "npcs", "npc"},
  {RELOAD_OUTFITS, "outfits", "outfit"},
  {RELOAD_QUESTS, "quests", "quest"},
  {RELOAD_RAIDS, "raids", "raid"},
  {RELOAD_SPELLS, "spells", "spell"},
  {RELOAD_STAGES, "stages", "experience"},
  {RELOAD_TALKACTIONS, "talkactions", "talk actions", "talk", "commands", "talkaction", "talk action"},
  {RELOAD_VOCATIONS, "vocations", "vocation"},
  {RELOAD_WEAPONS, "weapons", "weapon"},
  {RELOAD_MODS, "mods", "modifications"},
  {RELOAD_ALL, "all", "everything"}
}

-- Types that exist in the command list but are disabled / unused in C++ Game::reloadInfo
local disabledReload = {
  [RELOAD_GROUPS] = "groups (precisa restart — pointers de group nos players)",
  [RELOAD_HIGHSCORES] = "highscores (nao implementado no C++)",
  [RELOAD_ITEMS] = "items (nao implementado — precisa restart)",
  [RELOAD_MOUNTS] = "mounts (nao implementado no C++)",
  [RELOAD_OUTFITS] = "outfits (nao implementado — precisa restart)",
  [RELOAD_VOCATIONS] = "vocations (precisa restart — pointers nos players)",
  [RELOAD_WEAPONS] = "weapons (nao implementado — precisa restart)",
}

local function matchReloadAlias(param, entry)
  -- entry[1] is the numeric RELOAD_* id; only compare string aliases
  local aliases = {}
  for i = 2, #entry do
    aliases[#aliases + 1] = entry[i]
  end
  return table.isStrIn(param, aliases)
end

function onSay(cid, words, param, channel)
  if(param == '') then
    doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Command param required. Ex: /reload spells")
    return true
  end

  param = param:lower()
  local str = "Reload type not found."
  for _, v in ipairs(reloadInfo) do
    if(matchReloadAlias(param, v)) then
      local reloadId = v[1]
      if disabledReload[reloadId] then
        str = "Reload indisponivel: " .. disabledReload[reloadId]
      else
        doReloadInfo(reloadId, cid)
        str = "Reloading " .. v[2] .. "..."
      end
      break
    end
  end

  doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, str)
  return true
end
