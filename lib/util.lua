local utils = {}

local blitTable = {
  ["0"] = 1,
  ["1"] = 2,
  ["2"] = 4,
  ["3"] = 8,
  ["4"] = 16,
  ["5"] = 32,
  ["6"] = 64,
  ["7"] = 128,
  ["8"] = 256,
  ["9"] = 512,
  ["a"] = 1024,
  ["b"] = 2048,
  ["c"] = 4096,
  ["d"] = 8192,
  ["e"] = 16384,
  ["f"] = 32768
}

--- Draws a drawing char.
-- @param x number The x position.
-- @param y number The y position.
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

function utils.fromBlit(blit)
  return 2 ^ tonumber(blit, 16)
end

function utils.selectXfromBlit(x, blit)
  return blit:sub(x, x)
end

return utils