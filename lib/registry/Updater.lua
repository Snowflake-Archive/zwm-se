--- A standalone function for updating a registry.
-- @module[kind=registry] Updater

local expect = require("cc.expect").expect

--- Updates a registry
-- @tparam table from The registry to read from
-- @tparam table to The registry to write to
-- @return The new table
return function(old, new)
  expect(1, old, "table")
  expect(1, new, "table")

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