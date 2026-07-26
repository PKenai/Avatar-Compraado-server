local quest = {}

function quest:new(identifier)
  local ret = {identifier = identifier}
    setmetatable(ret, {__index = self})
    return ret
end

function createQuest(identifier)
  return quest:new(identifier)
end

function quest:setStartFunction(func)
  self.startFunc = func
end

function quest:setResetFunction(func)
  self.resetFunc = func
end

function quest:setStopFunction(func)
  self.stopFunc = func
end

function quest:setLoopFunction(func, time)
  self.loopFunc = func
  self.loopTime = time
end

function quest:reset()
  return self.resetFunc()
end

function quest:stop(...)
  self.hasStarted = false
  self:removeCreatures()
  self:removeEvents()
  self:reset()
  return self.stopFunc(...)
end

function quest:start(...)
  self:reset()
  self.hasStarted = true
  self.creatures = {}
  self.events = {}
  return self.startFunc(...)
end

function quest:loop()
  if self.hasStarted then
    self.loopFunc()  
  end
  addEvent(function(self) self:loop() end, self.loopTime, self)
end

function quest:hasOpened()
  return self.hasStarted
end

function quest:addEvent(func, delay, params)
  table.insert(self.events, addEvent(func, params, delay))
end

function quest:removeEvents()
  if self.events == nil then
    return
  end
  for x = 1, #self.events do
    stopEvent(self.events[x])
  end
end

function quest:addCreature(uid)
  table.insert(self.creatures, uid)
end

function quest:getCreatures()
  local creatures = {}
  for x = 1, #self.creatures do
    if isCreature(self.creatures[x]) then
      table.insert(creatures, sellf.creatures[x])
    end
  end
  return creatures
end

function quest:removeCreatures()
  if self.creatures == nil then
    return
  end
  for x = 1, #self.creatures do
    if isCreature(self.creatures[x]) then
      doRemoveCreature(self.creatures[x])
    end
  end
end


--create ZONE--

local zone = {}

function zone:new(identifier)
  local ret = {identifier = identifier}
    setmetatable(ret, {__index = self})
    return ret
end