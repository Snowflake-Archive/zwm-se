--- Util for reading registries
-- @module[kind=registry] Reader

local RegistryReader = {}

local file = require(".lib.utils.file")

--- Creates a new RegistryReader.
-- @tparam string name The name of the registry file
-- @tparam boolean fromDefaults If this is true, the registry will be read from the defaults folder
function RegistryReader:new(name, fromDefaults)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  self.name = name
  self.path = "/bin/Registry" .. (fromDefaults and "Defaults" or "") .. "/" .. name .. ".json"

  self.data = file.readJSON(self.path)

  return o
end

--- Reloads the registry.
-- @tparam[opt] table data If this is provided, data will be read from the table instead of the file
function RegistryReader:reload(data)
  if data then
    self.data = data
  else
    self.data = file.readJSON(self.path)
  end
end

--- Reads a key.
-- @tparam string key The key to read. This is in compressed table format (e.g. One.Two.Three)
-- @return any The value of the key
function RegistryReader:get(key)
  local children = self.data
  
  for t in key:gmatch("[^%.]+") do
    if children.folders[t] then
      children = children.folders[t]
    elseif children.values[t] then
      if children.values[t].type == "string" then
        return children.values[t].value
      elseif children.values[t].type == "number" then
        return tonumber(children.values[t].value)
      elseif children.values[t].type == "boolean" then
        return children.values[t].value == "true"
      elseif children.values[t].type == "table" then
        return textutils.unserialiseJSON(children.values[t].value)
      end

      return children.values[t].value
    else
      error("Key not found: " .. key)
    end
  end
end

--- Gets a key's type.
-- @tparam string key The key to read. This is in compressed table format (e.g. One.Two.Three)
-- @return string The type of the key (string, number, table or enum)
function RegistryReader:getType(key)
  local children = self.data
  
  for t in key:gmatch("[^%.]+") do
    if children.folders[t] then
      children = children.folders[t]
    elseif children.values[t] then
      return children.values[t].type
    else
      error("Key not found: " .. key)
    end
  end
end

--- Gets a key's enum values.
-- @tparam string key The key to read. This is in compressed table format (e.g. One.Two.Three)
-- @return table|nil The values of the enum.
function RegistryReader:getEnum(key)
  local children = self.data
  
  for t in key:gmatch("[^%.]+") do
    if children.folders[t] then
      children = children.folders[t]
    elseif children.values[t] then
      if children.values[t].type == "enum" then
        return children.values[t].enumValues
      end
    else
      error("Key not found: " .. key)
    end
  end
end

return RegistryReader