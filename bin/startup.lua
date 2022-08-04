local registry = require(".lib.registry")
local file = require(".lib.file")

print("Checking for registry updates...")

if fs.exists("/bin/Registry/machine.json") then
  local current = registry.readKey("/bin/RegistryDefaults/machine.json", "RegistryVersion", true)
  local old = registry.readKey("machine", "RegistryVersion")

  if current > old then
    print("Updating registry...")

    local currFull = registry.read("machine")
    local new = registry.read("/bin/RegistryDefaults/machine.json", true)
    file.writeJSON("/bin/Registry/machine.json", registry.update(currFull, new))
    print("Updated registry to version " .. current)
  end
else
  print("Creating registry...")
  local currentFull = registry.read("/bin/RegistryDefaults/machine.json", true)
  file.writeJSON("/bin/Registry/machine.json", registry.update({}, currentFull))
  print("Created registry")
end

print("Starting window manager...")
shell.run("/bin/wm.lua")