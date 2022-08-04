local file = require(".lib.file")

local registry = {}

--- Reads a full registry file.
-- @param from string The registry to read from (machine or user)
-- @param isRaw boolean Whether the path is raw or not
-- @return table The registry table
function registry.read(from, isRaw)
  local path = "/bin/Registry/" .. from .. ".json"
  local data = file.readJSON(isRaw and from or path)
  
  return data
end

--- Reads a key from a registry file.
-- @param from string The registry to read from (machine or user)
-- @param key string The key to read. This is in compressed table format (e.g. One.Two.Three)
-- @param isRaw boolean Whether the path is raw or not
-- @return string The value of the key
function registry.readKey(from, key, isRaw)
  local data = registry.read(from, isRaw)
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
-- @param from string The registry to write to (machine or user)
-- @param key string The key to write to. This is in compressed table format (e.g. One.Two.Three)
-- @param data any What to write to the key. This must be the same as what the item is defined as.
-- @return string The value of the key
function registry.writeKey(from, key, data)
  local children = registry.read(from)

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
  return children
end

--- Upgrades an old registry to a new one.
-- @param from table The registry to read from
-- @param to table The registry to write to
function registry.update(old, new)
  local function readFolder(old, new)
    local value = {
      values = {},
      folders = {}
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