local eventManager = {}

--- Creates a new event manager.
-- @return table The event manager
function eventManager:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self

  self.listeners = {}

  return o
end

--- Adds a listener to the event manager.
-- @param listener string|table The event to listen for. If this is a table, it is iterated through as a list of events. If this is a string, it is treated as a single event, with a required callback function.
-- @param callback function The callback to call when the event is fired
function eventManager:addListener(listener, callback)
  local function add(l, c)
    if self.listeners[listener] then
      table.insert(self.listeners[listener], callback)
    else
      self.listeners[listener] = {callback}
    end
  end

  if type(listener) == "table" then
    for l, v in ipairs(listener) do
      add(l, v)
    end
  else
    add(listener, callback)
  end
end

function eventManager:check(e)
  if self.listeners[e[1]] then
    for i, v in ipairs(self.listeners[e[1]]) do
      v(unpack(e, 2))
    end
  end
end

--- Starts listening for events.
-- @param[opt] useRaw boolean If this is true, os.pullEventRaw will be used rather than os.pullEvent
function eventManager:listen(useRaw)
  while true do
    local e = {(useRaw and os.pullEventRaw or os.pullEvent)()}

    if self.listeners[e[1]] then
      for i, v in ipairs(self.listeners[e[1]]) do
        v(unpack(e, 2))
      end
    end
  end
end

return eventManager