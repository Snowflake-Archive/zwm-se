--- Some utilities
-- @moudle[kind=core] Utils
-- @author Marcus Wenzel

local utils = {}

--- Draws a drawing char.
-- @tparam number x The x position.
-- @tparam number y The y position.
-- @tparam boolean tl Draw top left cell.
-- @tparam boolean tr Draw top right cell.
-- @tparam boolean l Draw middle left cell.
-- @tparam boolean r Draw middle left cell.
-- @tparam boolean bl Draw bottom left cell.
-- @tparam boolean br Draw bottom right cell.
-- @tparam number tc Foreground color
-- @tparam number bc Background color
-- @author thonkinator#8473
function utils.drawPixelCharacter(x, y, tl, tr, l, r, bl, br, tc, bc)
  term.setCursorPos(x,y)
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
  if not br then
    term.setBackgroundColor(bc)
    term.setTextColor(tc)
  else
    term.setBackgroundColor(tc)
    term.setTextColor(bc)
  end
  term.write(string.char(data))
  term.setBackgroundColor(bc)
  term.setTextColor(tc)
end

--- Converts a blit to a color number
-- @tparam string blit The blit char to convert
-- @return number The color
function utils.fromBlit(blit)
  return 2 ^ tonumber(blit, 16)
end

--- Converts a blit to a color number
-- @tparam number x The X position to pull
-- @tparam string blit The blit string to pull from
-- @return number The color
function utils.selectXfromBlit(x, blit)
  return blit:sub(x, x)
end

return utils