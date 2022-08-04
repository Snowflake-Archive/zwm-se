local events = require("lib.events")
local eventManager = events:new()

eventManager:addListener("char", function(...)
  print("Key Event", ...)
end)

eventManager:addListener("char", function(...)
  print("Key Event 2", ...)
end)

eventManager:listen()