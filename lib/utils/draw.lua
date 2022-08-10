--- Utilities for drawing things (borders and sub-pixel chars)
-- @module[kind=utils] Drawing

local drawing = {}
local utils = require(".lib.utils")

--- Draws a border around something.
-- @tparam number x The x position to start the border
-- @tparam number y The y position to start the border
-- @tparam number w The width of the border
-- @tparam number h The height of the border
-- @tparam number color The color of the border
-- @tparam string style The style to render in. The only available style is 1-box
function drawing.drawBorder(x, y, w, h, color, style)
  if style == "1-box" then
    local bg = term.getBackgroundColor()

    -- Top Line

    drawing.drawPixelCharacter(x, y, false, false, false, false, false, true, color, bg)
    
    local topDrawChar = utils.getPixelChar(false, false, false, false, true, true)
    term.setBackgroundColor(color)
    term.setTextColor(bg)
    term.write(topDrawChar:rep(w - 2))

    drawing.drawPixelCharacter(x + w - 1, y, false, false, false, false, true, false, color, bg)

    -- Sides
    local sideDrawChar = utils.getPixelChar(false, true, false, true, false, true)
    for i = 1, h - 2 do
      term.setBackgroundColor(color)
      term.setTextColor(bg)
      term.setCursorPos(x, y + i)
      term.write(sideDrawChar)
      term.setBackgroundColor(bg)
      term.setTextColor(color)
      term.setCursorPos(x + w - 1, y + i)
      term.write(sideDrawChar)
    end

    drawing.drawPixelCharacter(x, y + h - 1, false, true, false, false, false, false, color, bg)
    
    local bottomDrawChar = utils.getPixelChar(true, true, false, false, false, false)
    term.setBackgroundColor(bg)
    term.setTextColor(color)
    term.setCursorPos(x + 1, y + h - 1)
    term.write(bottomDrawChar:rep(w - 2))

    drawing.drawPixelCharacter(x + w - 1, y + h - 1, true, false, false, false, false, false, color, bg)
  end
end

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
function drawing.drawPixelCharacter(x, y, tl, tr, l, r, bl, br, tc, bc)
  term.setCursorPos(x, y)
  local char, invert = utils.getPixelChar(tl, tr, l, r, bl, br)

  if invert then
    term.setTextColor(bc)
    term.setBackgroundColor(tc)
  else
    term.setTextColor(tc)
    term.setBackgroundColor(bc)
  end

  term.write(char)
  term.setBackgroundColor(bc)
  term.setTextColor(tc)
end

return drawing