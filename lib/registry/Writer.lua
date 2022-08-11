--- Util for writing to registries
-- @module[kind=registry] Writer

local file = require(".lib.utils.file")

local RegistryWriter = {}

--- Creates a new RegistryWriter.
-- @tparam string name The name of the registry file
function RegistryWriter:new(name)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.name = name

  o.data = file.readJSON("/bin/Registry/" .. name .. ".json")
  
  return o
end

--- Sets a key.
-- @tparam string key The key to set. This is in compressed table format (e.g. One.Two.Three)
-- @tparam any value The value to set
-- @return The updated table.
function RegistryWriter:set(key, value)
  local children = self.data

  local t = children
  local items = {"folders"}

  local matchedRaw = {}
  for m in key:gmatch("[^%.]+") do
    table.insert(matchedRaw, m)
  end

  for i, v in pairs(matchedRaw) do
    table.insert(items, v)

    if i == #matchedRaw - 1 then
      table.insert(items, "values")
    elseif i ~= #matchedRaw then
      table.insert(items, "folders")
    end
  end

  table.insert(items, "value")
  table.insert(items, tostring(value))

  for i = 1, #items - 2 do
    local k = items[i]
    t[k] = t[k] or {}
    t = t[k]
  end

  t[items[#items - 1]] = items[#items]
  file.writeJSON("/bin/Registry/" .. self.name .. ".json", children)

  os.queueEvent("registry_update", self.name, key)

  self.data = children
  return children
end

return RegistryWriter