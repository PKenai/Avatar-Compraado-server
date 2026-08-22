-- private variables
local topMenu
local leftButtonsPanel
local rightButtonsPanel
local leftGameButtonsPanel
local rightGameButtonsPanel
local fpsEvent
local fpsText = ''

-- drawer variables
local idleTimer = nil
local isHidden = false
local isAnimating = false
local IDLE_TIMEOUT = 15000 -- 15 seconds
local ANIM_DURATION = 300  -- ms
local ANIM_STEPS = 20
local originalY = nil
local dropButton = nil

-- private functions
local function addButton(id, description, icon, callback, panel, toggle, front)
  local class
  if toggle then
    class = 'TopToggleButton'
  else
    class = 'TopButton'
  end

  local button = panel:getChildById(id)
  if not button then
    button = g_ui.createWidget(class)
    if front then
      panel:insertChild(1, button)
    else
      panel:addChild(button)
    end
  end
  button:setId(id)
  button:setTooltip(description)
  button:setIcon(resolvepath(icon, 3))
  button.onMouseRelease = function(widget, mousePos, mouseButton)
    if widget:containsPoint(mousePos) and mouseButton ~= MouseMiddleButton then
      callback()
      return true
    end
  end
  return button
end

-- drawer functions
local function resetIdleTimer()
  if idleTimer then
    removeEvent(idleTimer)
    idleTimer = nil
  end
  if not isHidden and not isAnimating then
    idleTimer = scheduleEvent(function()
      if isHidden or isAnimating then return end
      isAnimating = true
      local startY = topMenu:getY()
      local height = topMenu:getHeight()
      local targetY = startY - height

      -- show drop button immediately
      if dropButton then
        dropButton:show()
        dropButton:setOpacity(0)
        g_effects.fadeIn(dropButton, 200)
      end

      -- animate slide up
      for i = 1, ANIM_STEPS do
        scheduleEvent(function()
          if topMenu and isAnimating then
            local progress = i / ANIM_STEPS
            local eased = 1 - (1 - progress) * (1 - progress) -- ease out quad
            local newY = startY + (targetY - startY) * eased
            topMenu:setY(math.floor(newY))
            if i == ANIM_STEPS then
              topMenu:setY(targetY)
              isHidden = true
              isAnimating = false
            end
          end
        end, math.floor(i * ANIM_DURATION / ANIM_STEPS))
      end
    end, IDLE_TIMEOUT)
  end
end

local function slideDown()
  if isAnimating or not isHidden then return end
  isAnimating = true

  -- hide drop button
  if dropButton then
    g_effects.fadeOut(dropButton, 150)
    scheduleEvent(function()
      if dropButton then dropButton:hide() end
    end, 160)
  end

  local startY = topMenu:getY()
  local targetY = originalY or 0

  for i = 1, ANIM_STEPS do
    scheduleEvent(function()
      if topMenu and isAnimating then
        local progress = i / ANIM_STEPS
        local eased = progress * progress -- ease in quad
        local newY = startY + (targetY - startY) * eased
        topMenu:setY(math.floor(newY))
        if i == ANIM_STEPS then
          topMenu:setY(targetY)
          isHidden = false
          isAnimating = false
          resetIdleTimer()
        end
      end
    end, math.floor(i * ANIM_DURATION / ANIM_STEPS))
  end
end

function onTopMenuHover(self)
  if not isHidden and not isAnimating then
    resetIdleTimer()
  end
end

function onDropClick()
  slideDown()
end

-- public functions
function init()
  connect(g_game, { onGameStart = online,
                    onGameEnd = offline,
                    onPingBack = updatePing })

  topMenu = g_ui.displayUI('topmenu')

  leftButtonsPanel = topMenu:getChildById('leftButtonsPanel')
  rightButtonsPanel = topMenu:getChildById('rightButtonsPanel')
  leftGameButtonsPanel = topMenu:getChildById('leftGameButtonsPanel')
  rightGameButtonsPanel = topMenu:getChildById('rightGameButtonsPanel')
  pingLabel = topMenu:getChildById('pingLabel')
  fpsLabel = topMenu:getChildById('fpsLabel')

  -- store original Y for drawer animation
  originalY = topMenu:getY()

  -- create drop button as a top-level widget (NOT child of topMenu)
  dropButton = g_ui.createWidget('Image')
  dropButton:setId('dropButton')
  dropButton:setImage(resolvepath('/data/images/topbuttons/drop.png', 3))
  dropButton:setTooltip('Mostrar barra superior')
  dropButton:setOpacity(0.7)
  dropButton:hide()

  -- position at top center of root
  local root = g_ui.getRootWidget()
  dropButton:setParent(root)
  dropButton:setAnchor('top', root, 'top')
  dropButton:setAnchor('horizontalCenter', root, 'horizontalCenter')
  dropButton:setMarginTop(2)

  dropButton.onMouseRelease = function(widget, mousePos, mouseButton)
    if widget:containsPoint(mousePos) and mouseButton == MouseLeftButton then
      onDropClick()
      return true
    end
  end
  dropButton.onHoverChange = function(widget)
    if widget:isHovered() then
      widget:setOpacity(1.0)
    else
      widget:setOpacity(0.7)
    end
  end

  -- Update the FPS counter by polling g_app.getFps() once per second.
  updateFps()
  fpsEvent = cycleEvent(function() updateFps() end, 1000)

  if g_game.isOnline() then
    online()
  end
end

function terminate()
  disconnect(g_game, { onGameStart = online,
                       onGameEnd = offline,
                       onPingBack = updatePing })

  if fpsEvent then
    removeEvent(fpsEvent)
    fpsEvent = nil
  end

  if idleTimer then
    removeEvent(idleTimer)
    idleTimer = nil
  end

  if dropButton then
    dropButton:destroy()
    dropButton = nil
  end

  topMenu:destroy()
end

function online()
  showGameButtons()
  g_game.enableFeature(GameClientPing)
  addEvent(function()
    fpsLabel:show()
    pingLabel:show()
    -- ensure topmenu is visible and positioned correctly
    if isHidden then
      topMenu:show()
      topMenu:setY(originalY or 0)
      isHidden = false
      isAnimating = false
      if dropButton then dropButton:hide() end
    end
    resetIdleTimer()
  end)
end

function offline()
  hideGameButtons()
  pingLabel:hide()
  if idleTimer then
    removeEvent(idleTimer)
    idleTimer = nil
  end
  -- reset drawer state when going offline
  if isHidden then
    topMenu:show()
    topMenu:setY(originalY or 0)
    isHidden = false
    isAnimating = false
  end
  if dropButton then
    dropButton:hide()
  end
end

function updateFps(fps)
  fps = fps or g_app.getFps()
  if fps < 0 then fps = 0 end
  local text = 'FPS: ' .. fps
  if text ~= fpsText then
    fpsText = text
    fpsLabel:setText(text)
  end
end

function updatePing(ping)
  ping = math.ceil(ping/4)
  local text = 'PING: '
  local color
  if ( ping <= 70 ) then
    color = 'green'
  elseif ( ping <= 130 ) then
    color = 'yellow'
  else
    color = 'red'
  end
  text = text .. ping .. ' ms'
  
  pingLabel:setColor(color)
  pingLabel:setText(text)
  pingLabel:setVisible(ping >= 1)
end

function setPingVisible(enable)
  pingLabel:setVisible(enable)
end

function setFpsVisible(enable)
  fpsLabel:setVisible(enable)
end

function addLeftButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, false, front)
end

function addLeftToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, true, front)
end

function addRightButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, false, front)
end

function addRightToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, true, front)
end

function addLeftGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, true, front)
end

function addLeftGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, true, front)
end

function addRightGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, false, front)
end

function addRightGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, true, front)
end

function showGameButtons()
  leftGameButtonsPanel:show()
  rightGameButtonsPanel:show()
end

function hideGameButtons()
  leftGameButtonsPanel:hide()
  rightGameButtonsPanel:hide()
end

function getButton(id)
  return topMenu:recursiveGetChildById(id)
end

function getTopMenu()
  return topMenu
end
