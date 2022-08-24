--- Miscellaneous utilities
-- @module[kind=utils] MiscUtils

local utils = {}
local expect = require("cc.expect").expect

local floor = math.floor

--- Gets a drawing character from the cells that are set to true.
-- @tparam boolean tl Draw top left cell.
-- @tparam boolean tr Draw top right cell.
-- @tparam boolean l Draw middle left cell.
-- @tparam boolean r Draw middle left cell.
-- @tparam boolean bl Draw bottom left cell.
-- @tparam boolean br Draw bottom right cell.
function utils.getPixelChar(tl, tr, l, r, bl, br)
  expect(1, tl, "boolean")
  expect(2, tr, "boolean")
  expect(3, l, "boolean")
  expect(4, r, "boolean")
  expect(5, bl, "boolean")
  expect(6, br, "boolean")

  local data = 128
  if not br then
    data = data + (tl and 1 or 0)
    data = data + (tr and 2 or 0)
    data = data + (l and 4 or 0)
    data = data + (r and 8 or 0)
    data = data + (bl and 16 or 0)
  else
    data = data + (tl and 0 or 1)
    data = data + (tr and 0 or 2)
    data = data + (l and 0 or 4)
    data = data + (r and 0 or 8)
    data = data + (bl and 0 or 16)
  end

  return string.char(data), br
end

--- Selects an X position from a blit string (or just any string really)
-- @tparam number x The X position to pull
-- @tparam string blit The blit string to pull from
-- @return number The color
function utils.selectXfromBlit(x, blit)
  expect(1, x, "number")
  expect(2, blit, "string")

  return blit:sub(x, x)
end

--- Gets a semi-random UUID.
-- @return string The UUID
function utils.uuid()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function (c)
    local v = c == 'x' and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format('%x', v)
  end)
end

--- Checks if a table contains a value.
-- @tparam table tbl The table to check
-- @tparam any val The value to check for
function utils.tableContains(tbl, val)
  expect(1, tbl, "table")
  
  for _, v in pairs(tbl) do
    if v == val then return true end
  end
  return false
end

--- Stringifies time into a nice, human readable format.
-- @tparam number time The time to stringify
-- @return string The stringified time
function utils.stringifyTime(ms)
  if ms < 1000 then -- milliseconds
    return tostring(floor(ms)) .. "ms"
  elseif ms < 60 * 1000 then -- seconds
    return tostring(floor(ms / 1000)) .. "s"
  elseif ms < 60 * 60 * 1000 then -- minutes
    return tostring(floor(ms / 1000 / 60)) .. "m"
  elseif ms < 24 * 60 * 60 * 1000 then -- hours
    return tostring(floor(ms / 1000 / 60 / 60)) .. "h"
  else -- days
    return tostring(floor(ms / 1000 / 60 / 60 / 24)) .. "d"
  end
end

--- Clones a table.
-- @tparam table tbl The table to clone
-- @return table The cloned table
function utils.tableClone(tbl)
  expect(1, tbl, "table")
  
  return {table.unpack(tbl)}
end

return utils