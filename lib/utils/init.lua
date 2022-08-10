--- Miscellaneous utilities
-- @module[kind=utils] MiscUtils

local utils = {}

--- Gets a drawing character from the cells that are set to true.
-- @tparam boolean tl Draw top left cell.
-- @tparam boolean tr Draw top right cell.
-- @tparam boolean l Draw middle left cell.
-- @tparam boolean r Draw middle left cell.
-- @tparam boolean bl Draw bottom left cell.
-- @tparam boolean br Draw bottom right cell.
function utils.getPixelChar(tl, tr, l, r, bl, br)
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
  for _, v in pairs(tbl) do
    if v == val then return true end
  end
  return false
end

return utils