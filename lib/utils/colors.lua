--- Utilities for colors
-- @module[kind=utils] Color

local utils = {}
local expect = require("cc.expect").expect

--- Converts a blit to a color number
-- @tparam string blit The blit char to convert
-- @return number The color
function utils.fromBlit(blit)
  expect(1, blit, "string")
  return 2 ^ tonumber(blit, 16)
end

return utils