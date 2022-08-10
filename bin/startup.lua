local registry = require(".lib.registry")
local file = require(".lib.file")

print("Checking for registry updates...")

local function updateRegistry(version)
  local path = ("/bin/RegistryDefaults/%s.json"):format(version)
  local save = ("/bin/Registry/%s.json"):format(version)

  if fs.exists(save) then
    local current = registry.readKey(path, "RegistryVersion", true)
    local old = registry.readKey("machine", "RegistryVersion")

    if current > old then
      print("Updating " .. version .. " registry...")

      local currFull = registry.read("machine")
      local new = registry.read(path, true)
      file.writeJSON(save, registry.update(currFull, new))
      print("Updated " .. version .. " registry to version " .. current)
    end
  else
    print("Creating " .. version .. " registry...")
    local currentFull = registry.read(path, true)
    file.writeJSON(save, registry.update({}, currentFull))
    print("Created " .. version .. " registry")
  end
end

updateRegistry("machine")
updateRegistry("user")

print("Starting window manager...")
shell.run("/bin/wm.lua")