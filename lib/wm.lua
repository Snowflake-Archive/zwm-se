local wm = {}

function wm.launch(object, options, focused)
  local initID = (math.random(1, 50) * os.epoch("utc")) / 100
  os.queueEvent("launchProgram", initID, object, options, focused)
end

function wm.getSystemLogger()
  os.queueEvent("getSystemLogger")
  local e, sysl

  repeat
    e, sysl = os.pullEvent("gotSystemLogger")
  until e == "gotSystemLogger" and sysl ~= nil
  return sysl
end

return wm