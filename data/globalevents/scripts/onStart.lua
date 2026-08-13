local MyLocal = {}
MyLocal.npcsCiviliansPoses = {{x=557,y=384,z=7}, {x=559,y=386,z=7}, {x=560,y=386,z=7}}

MyLocal.outfits = {
  {
    lookType = 128,
    lookFeet = 0,
    lookBody = 94,
    lookHead = 114,
    lookLegs = 114,
    lookAddons = 0
  },

  {
    lookType = 144,
    lookFeet = 114,
    lookBody = 76,
    lookHead = 79,
    lookLegs = 76,
    lookAddons = 3
  },
  {
    lookType = 138,
    lookFeet = 0,
    lookBody = 95,
    lookHead = 114,
    lookLegs = 76,
    lookAddons = 0
  }
}

local function change()
  local newNpcList = shuffleList(MyLocal.outfits)

  for x = 1, #MyLocal.npcsCiviliansPoses do
    local npcUid = doCreateNpc("civilian", MyLocal.npcsCiviliansPoses[x])
    doSetCreatureOutfit(npcUid, MyLocal.outfits[x])
    doCreatureSetLookDirection(npcUid, NORTH)
  end
end

function onStartup()
  addEvent(change, 1000, nil)
  setNewDay()
  

  return true
end

