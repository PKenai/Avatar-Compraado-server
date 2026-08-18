local configMarks = {
  version = 1, -- Increase this value after adding new marks, so player can step again and receive new map marks
  marks = {
    {mark = 8, pos = {x=561,y=431,z=7}, desc = "Undead Monsters"},
    {mark = 8, pos = {x=521,y=436,z=7}, desc = "Tasks and Trolls"},
    {mark = 8, pos = {x=424,y=419,z=7}, desc = "Giants"},
    {mark = 8, pos = {x=434,y=464,z=7}, desc = "Elfos"},
    {mark = 8, pos = {x=645,y=567,z=7}, desc = "Underwater Monsters"},
    {mark = 8, pos = {x=650,y=529,z=7}, desc = "Undead Monsters"},
    {mark = 8, pos = {x=436,y=435,z=7}, desc = "Dwarves Monsters"},
    {mark = 2, pos = {x=592,y=367,z=7}, desc = "Boat"},
    {mark = 2, pos = {x=674,y=517,z=7}, desc = "Boat"},
    {mark = 2, pos = {x=452,y=599,z=7}, desc = "Boat"},
  }
}

local function sendMapMarks(cid)
  if isPlayer(cid) ~= true then
    return false
  end
  for _, m  in pairs(configMarks.marks) do
    doPlayerAddMapMark(cid, m.pos, m.mark, m.desc ~= nil and m.desc or "")
    end
    return true
end

local playerHasDo = {}

function onSay(cid, words, param, channel)
  --sendBlueMessage(cid, getLangString(cid, "Are you lost? See our world map: http://vaatu.avatarworld.com.br/?subtopic=worldmap", "Está perdido? Veja nosso world map: www.avatarlegendsonline.com.br/?subtopic=worldmap"))
  return true
end

