local drawUtils = require('.lib.utils.draw')
local events = require('.lib.events'):new()
local focusableEventManager = require('.lib.ui.focusableEventManager')

local function render()
  local w, h = term.getSize()
  term.setBackgroundColor(colors.white)
  drawUtils.drawBorder(1, 1, w, h, colors.lightBlue, "1-box-outside")
end

events:addListener("term_resize", render)

while true do
  sleep(1)
end