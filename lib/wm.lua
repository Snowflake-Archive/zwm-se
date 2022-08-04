--- Wrappers for window manager functions
-- @moudle[kind=core] WindowManagerWrapper
-- @author Marcus Wenzel

local wm = {}

--- Launches a program.
-- @tparam string object The path to the program to launch, or function
-- @tparam table options The arguments to pass to the program
-- @tparam[opt] table focused Whether or not the program is focused when launched
function wm.launch(object, options, focused)
  local initID = (math.random(1, 50) * os.epoch("utc")) / 100
  os.queueEvent("launchProgram", initID, object, options, focused)
end

--- Gets the system's logger.
-- @return Logger The logger
function wm.getSystemLogger()
  os.queueEvent("getSystemLogger")
  local e, sysl

  repeat
    e, sysl = os.pullEvent("gotSystemLogger")
  until e == "gotSystemLogger" and sysl ~= nil
  return sysl
end

return wm