--- A basic event manager, allows for adding multiple listeners to an event.
-- @module[kind=core] EventManager

local eventManager = {}

local expect = require("cc.expect").expect

--- Creates a new event manager.
-- @return EventManager The event manager
function eventManager:new()
  local o = {listeners = {}, isStopped = false}
  setmetatable(o, self)
  self.__index = self

  return o
end

--- Stops the event manager.
function eventManager:stop()
  self.isStopped = true
end

--- Adds a listener to the event manager.
-- @tparam string|table listener The event to listen for. If this is a table, it is iterated through as a list of events. If this is a string, it is treated as a single event, with a required callback function.
-- @tparam function callback The callback to call when the event is fired
function eventManager:addListener(listener, callback)
  expect(1, listener, "string", "table")
  expect(2, callback, "function", "nil")

  if type(listener) == "table" then
    for i, v in pairs(listener) do
      if self.listeners[i] then
        table.insert(self.listeners[i], v)
      else
        self.listeners[i] = {v}
      end
    end
  else
    if self.listeners[listener] then
      table.insert(self.listeners[listener], callback)
    else
      self.listeners[listener] = {callback}
    end
  end
end

--- Checks events.
-- @tparam table e A packed os.pullEvent response.
function eventManager:check(e)
  expect(1, e, "table")

  if self.listeners[e[1]] then
    for _, v in ipairs(self.listeners[e[1]]) do
      v(unpack(e, 2))
    end
  end
end

--- Starts listening for events.
-- @tparam[opt] boolean useRaw If this is true, os.pullEventRaw will be used rather than os.pullEvent
function eventManager:listen(useRaw)
  expect(1, useRaw, "boolean", "nil")
  
  self.isStopped = false
  while true do
    local e = {(useRaw and os.pullEventRaw or os.pullEvent)()}

    if self.isStopped == true then
      break
    end

    if self.listeners[e[1]] then
      for _, v in ipairs(self.listeners[e[1]]) do
        v(unpack(e, 2))
      end
    end
  end
end

return eventManager