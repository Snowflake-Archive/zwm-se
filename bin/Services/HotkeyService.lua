local wm = require(".lib.wm")
local logger = wm.getSystemLogger()

local debounce = false
local w, h = term.getSize()

local hotkeys = {
  {
    name = "Open Run Menu (CTRL+SHIFT+R)",
    keys = {keys.leftCtrl, keys.leftShift, keys.r},
    f = function()
      wm.launch("/bin/run.lua", {
        w = 27,
        h = 7,
        x = 2,
        y = h - 8,
        title = "Run",
        isResizeable = false,
        hideMaximize = true,
        hideMinimize = true,
      }, true)
    end
  }
}

local heldKeys = {}

logger:info("[HotkeyService] Hotkey service started")

while true do
  local e = {os.pullEvent()}

  if e[1] == "key" then
    heldKeys[e[2]] = true
    debounce = false
  elseif e[1] == "key_up" then
    heldKeys[e[2]] = nil
    debounce = false
  elseif e[1] == "term_resize" then
    w, h = term.getSize()
  end

  if debounce == false then
    for i, v in pairs(hotkeys) do
      local ok = true

      for _, k in pairs(v.keys) do
        if heldKeys[k] ~= true then
          ok = false
          break
        end
      end

      local heldCount = 0

      for i, v in pairs(heldKeys) do
        if v == true then
          heldCount = heldCount + 1
        end
      end

      if heldCount ~= #v.keys then
        ok = false
      end

      if ok then
        logger:debug("[HotkeyService] Hotkey pressed: %s", v.name)
        v.f()
        debounce = true
      end
    end
  end
end