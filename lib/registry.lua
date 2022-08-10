--- Registry getter & editor utilities
-- @deprecated Soon to be replaced with RegistryReader & RegistryWriter.
-- @module[kind=core] Registry

local file = require(".lib.file")

local registry = {}

--- Reads a full registry file.
-- @deprecated Use RegistryReader instead.
-- @param from string The registry to read from (machine or user)
-- @param isRaw boolean Whether the path is raw or not
-- @return table The registry table
function registry.read(from, isRaw)
  local path = "/bin/Registry/" .. from .. ".json"
  local data = file.readJSON(isRaw and from or path)
  
  return data
end

--- Reads a key from a registry file.
-- @deprecated Use RegistryReader instead.
-- @param from string The registry to read from (machine or user)
-- @param key string The key to read. This is in compressed table format (e.g. One.Two.Three)
-- @param isRaw boolean Whether the path is raw or not
-- @param data table The registry table to read from
-- @return string The value of the key
function registry.readKey(from, key, isRaw, data)
  local data = data or registry.read(from, isRaw)
  local children = data
  
  for t in key:gmatch("[^%.]+") do
    if children.folders[t] then
      children = children.folders[t]
    else
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
    end
  end
end

--- Gets a key's type.
-- @deprecated Use RegistryReader instead.
-- @param from string The registry to read from (machine or user)
-- @param key string The key to read. This is in compressed table format (e.g. One.Two.Three)
function registry.getKeyType(from, key)
  local data = registry.read(from)
  local children = data
  
  for t in key:gmatch("[^%.]+") do
    if children.folders[t] then
      children = children.folders[t]
    else
      return children.values[t].type
    end
  end
end

--- Gets a key's enum values.
-- @deprecated Use RegistryReader instead.
-- @param from string The registry to read from (machine or user)
-- @param key string The key to read. This is in compressed table format (e.g. One.Two.Three)
function registry.getEnumValues(from, key)
  local data = registry.read(from)
  local children = data
  
  for t in key:gmatch("[^%.]+") do
    if children.folders[t] then
      children = children.folders[t]
    else
      if children.values[t].type == "enum" then
        return children.values[t].enumValues
      end
    end
  end
end

--- Reads a key from a registry file.
-- @deprecated
-- @param from string The registry to write to (machine or user)
-- @param key string The key to write to. This is in compressed table format (e.g. One.Two.Three)
-- @param data any What to write to the key. This must be the same as what the item is defined as.
-- @param children table What to search in
-- @return string The value of the key
function registry.writeKey(from, key, data, children)
  local children = children or registry.read(from)

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
  table.insert(items, tostring(data))

  for i = 1, #items - 2 do
    local k = items[i]
    t[k] = t[k] or {}
    t = t[k]
  end

  t[items[#items - 1]] = items[#items]
  file.writeJSON("/bin/Registry/" .. from .. ".json", children)

  os.queueEvent("registry_update", from, key)

  return children
end

--- Upgrades an old registry to a new one.
-- @deprecated
-- @tparam table from The registry to read from
-- @tparam table to The registry to write to
-- @return The table that was created
function registry.update(old, new)
  local function readFolder(old, new)
    local value = {
      values = {},
      folders = {},
    }

    for i, v in pairs(new.values) do
      if old[i] == nil or v.overrideOnUpdate == true then
        value.values[i] = {}
        value.values[i].value = v.value
        value.values[i].type = v.type
        value.values[i].enumValues = v.enumValues
      end
    end

    for i, v in pairs(new.folders) do
      if old[i] == nil then
        value.folders[i] = v
      else
        value.folders[i] = readFolder(old[i], v)
      end
    end
    return value
  end

  return readFolder(old, new)
end

return registry