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

local ScrollDesktop = {}
ScrollDesktop.__index  = ScrollDesktop
ScrollDesktop.name     = "ScrollDesktop"
ScrollDesktop.version  = "0.1"
ScrollDesktop.author   = "John Ankarström"
ScrollDesktop.homepage = "https://github.com/jocap/ScrollDesktop.spoon"
ScrollDesktop.license  = "MIT - https://opensource.org/licenses/MIT"

function ScrollDesktop:start()
   self.triggerSwipe = false
   self.exemptWindow = nil
   self.onlyWindow = nil
   self.onlyRightOf = nil
   self.currentWindows = nil
   self.positions = {}
   self.xmax = hs.screen.mainScreen():fullFrame().w
   self.tap = hs.eventtap.new(
      {hs.eventtap.event.types.scrollWheel}, function(event)
	 local dx = event:getProperty(hs.eventtap.event.properties.scrollWheelEventPointDeltaAxis2)
	 local begin = event:getProperty(hs.eventtap.event.properties.scrollWheelEventScrollPhase) == 1
	 if begin then
	    local window = get_window_under_mouse()
	    local mod = hs.eventtap.checkKeyboardModifiers()
	    self.triggerSwipe = window == nil or mod.cmd
	    if window ~= nil and mod.shift then
	       self.exemptWindow = window:id()
	    else
	       self.exemptWindow = nil
	    end
	    if window ~= nil and mod.alt then
	       self.onlyWindow = window
	    else
	       self.onlyWindow = nil
	    end
	    if mod.ctrl then
	       self.onlyRightOf = hs.mouse:getRelativePosition().x
	    else
	       self.onlyRightOf = nil
	    end
	 end
	 if self.triggerSwipe then
	    if begin then
	       if self.onlyWindow == nil then
		  self.currentWindows = hs.window.orderedWindows()
	       else
		  self.currentWindows = {self.onlyWindow}
		  self.onlyWindow:focus()
	       end
	    end
	    for i, window in pairs(self.currentWindows) do
	       local id = window:id()
	       if id ~= self.exemptWindow then
		  local topleft = self.positions[id]
		  if self.positions[id] == nil then
		     topleft = window:topLeft()
		  end
		  local allow = true
		  local x = topleft.x+dx
		  if self.onlyRightOf ~= nil then
		     local diff = topleft.x-self.onlyRightOf
		     if diff < 0 or diff == 0 and dx < 0 then
			allow = false
		     end
		     if topleft.x+dx <= self.onlyRightOf then
			x = self.onlyRightOf+1
		     end
		  end
		  if allow then
		     local outside = false
		     if x > self.xmax-1 then
			self.positions[id] = {x=topleft.x+dx, y=topleft.y}
			x = self.xmax-1
			outside = true
		     else
			local minx = -window:size().w
			if x < minx+1 then
			   self.positions[id] = {x=topleft.x+dx, y=topleft.y}
			   x = minx+1
			   outside = true
			end
		     end
		     if self.onlyWindow ~= nil then
			local pos = hs.mouse.getRelativePosition()
			pos.x = pos.x+x-window:topLeft().x
			hs.mouse.setRelativePosition(pos)
		     end
		     window:setTopLeft(x, topleft.y)
		     if not outside then self.positions[id] = nil end
		  end
	       end
	    end
	    return true
	 end
      end
   ):start()
end

function ScrollDesktop:stop()
   if self.tap then
      self.tap:stop()
      self.tap = nil
   end
end

return ScrollDesktop
