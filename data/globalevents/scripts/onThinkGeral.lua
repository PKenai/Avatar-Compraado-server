local MyLocal = {}
MyLocal.magicEffectInfo = {pos = {x=559,y=358,z=11,}, ids = {55, 56}}

function onThink(interval)
  for x = 1, #MyLocal.magicEffectInfo.ids do
    doSendMagicEffect(MyLocal.magicEffectInfo.pos, MyLocal.magicEffectInfo.ids[x])
  end
 -- if getPlayerByNameWildcard("Otto") then 
--	doPlayerSetGroupId(getPlayerByNameWildcard("Otto"), 6)
 -- end 
  return true
end