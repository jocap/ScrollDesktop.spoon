-- from https://gist.github.com/kizzx2/e542fa74b80b7563045a
function get_window_under_mouse()
  -- Invoke `hs.application` because `hs.window.orderedWindows()` doesn't do it
  -- and breaks itself
  local _ = hs.application

  local my_pos = hs.geometry.new(hs.mouse.absolutePosition())
  local my_screen = hs.mouse.getCurrentScreen()

  return hs.fnutils.find(hs.window.orderedWindows(), function(w)
    return my_screen == w:screen() and my_pos:inside(w:frame())
  end)
end

local scrollWheel <const> = hs.eventtap.event.types.scrollWheel
local scrollWheelEventPointDeltaAxis1 <const> = hs.eventtap.event.properties.scrollWheelEventPointDeltaAxis1
local scrollWheelEventPointDeltaAxis2 <const> = hs.eventtap.event.properties.scrollWheelEventPointDeltaAxis2
local scrollWheelEventScrollPhase <const> = hs.eventtap.event.properties.scrollWheelEventScrollPhase

local ScrollDesktop = {}
ScrollDesktop.__index  = ScrollDesktop
ScrollDesktop.name     = "ScrollDesktop"
ScrollDesktop.version  = "0.1"
ScrollDesktop.author   = "John Ankarström"
ScrollDesktop.homepage = "https://github.com/jocap/ScrollDesktop.spoon"
ScrollDesktop.license  = "MIT - https://opensource.org/licenses/MIT"

function ScrollDesktop:start(opt)
  if opt == nil then opt = {} end
  self.scrollWheelTap = {}
  self.triggerSwipe = false
  self.exemptWindow = nil
  self.onlyWindow = nil
  self.onlyRightOf = nil
  self.currentWindows = nil
  self.positions = {}
  self.xmax = hs.screen.mainScreen():fullFrame().w

  self.tap = hs.eventtap.new({scrollWheel}, function(event)
    local beginEvent = event:getProperty(scrollWheelEventScrollPhase) == 1
    local dx = event:getProperty(scrollWheelEventPointDeltaAxis2)

    -- At the beginning of the scroll, determine the type of scroll.
    if beginEvent then
      local dy = event:getProperty(scrollWheelEventPointDeltaAxis1)
      local window = get_window_under_mouse()
      local mod = hs.eventtap.checkKeyboardModifiers()

      -- Scroll windows only if pointer is not above window or Cmd is held.
      if opt.everywhere then
        self.triggerSwipe = math.abs(dy) < 5 and math.abs(dx) > 0 and not mod.cmd
      else
        self.triggerSwipe = window == nil or mod.cmd
      end

      -- Exempt window under pointer from scroll if Shift is held.
      if window ~= nil and mod.shift then
        window:focus()
        self.exemptWindow = window:id()
      else
        self.exemptWindow = nil
      end

      -- Scroll only window under pointer if Option is held.
      if window ~= nil and mod.alt then
        window:focus()
        self.onlyWindow = window
      else
        self.onlyWindow = nil
      end

      -- Scroll only windows to the right of pointer if Ctrl is held.
      if mod.ctrl then
        self.onlyRightOf = hs.mouse:getRelativePosition().x
      else
        self.onlyRightOf = nil
      end

      -- Collect windows to be scrolled.
      if self.triggerSwipe then
        if self.onlyWindow == nil then
          self.currentWindows = hs.window.orderedWindows()
        else
          self.currentWindows = {self.onlyWindow}
        end
      end
    end

    -- Scroll windows.
    if self.triggerSwipe then
      self:scrollWindows(dx)
      return true
    end
  end)
  self.tap:start()
end

function ScrollDesktop:scrollWindows(dx)
  for i, window in pairs(self.currentWindows) do
    local id = window:id()

    -- Don't scroll exempt window.
    if id ~= self.exemptWindow then
      -- Get real or virtual position of window.
      local topleft = self.positions[id]
      if self.positions[id] == nil then
        topleft = window:topLeft()
      end

      -- Don't scroll windows to the left if Ctrl is held.
      local isRight = true
      local x = topleft.x+dx
      if self.onlyRightOf ~= nil then
        local diff = topleft.x-self.onlyRightOf
        if diff < 0 or diff == 0 and dx < 0 then
          isRight = false
        end
        if topleft.x+dx <= self.onlyRightOf then
          x = self.onlyRightOf+1
        end
      end

      if isRight then
        -- If window is at screen edge ("outside"), then use
        -- virtual instead of real positions.
        local isOutside = false
        if x > self.xmax-1 then
          self.positions[id] = {x=topleft.x+dx, y=topleft.y}
          x = self.xmax-1
          isOutside = true
        else
          local minx = -window:size().w
          if x < minx+1 then
            self.positions[id] = {x=topleft.x+dx, y=topleft.y}
            x = minx+1
            isOutside = true
          end
        end

        -- Move pointer with window if Option is held.
        if self.onlyWindow ~= nil then
          local pos = hs.mouse.getRelativePosition()
          pos.x = pos.x+x-window:topLeft().x
          hs.mouse.setRelativePosition(pos)
        end

        -- Set real window position.
        window:setTopLeft(x, topleft.y)

        -- Remove virtual window position if window is "inside".
        if not isOutside then self.positions[id] = nil end
      end
    end
  end
end

function ScrollDesktop:stop()
  if self.tap then
    self.tap:stop()
    self.tap = nil
  end
end

return ScrollDesktop
