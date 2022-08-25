local functions = {}

function functions.clearCrashReports()
  os.run("/rom/programs/rm.lua /crash-*.txt")
  return true
end

return functions