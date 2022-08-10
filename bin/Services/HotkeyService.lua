local logger = _ENV.wm.getSystemLogger()

local debounce = false
local _, h = term.getSize()

local hotkeys = {
  {
    name = "Open Run Menu (CTRL+SHIFT+R)",
    keys = {keys.leftCtrl, keys.leftShift, keys.r},
    f = function()
      _ENV.wm.addProcess("/bin/run.lua", {
        w = 27,
        h = 9,
        x = 2,
        y = h - 10,
        title = "Run",
        isResizeable = false,
        hideMaximize = true,
        hideMinimize = true,
      }, true)
    end,
  },
  {
    name = "Open Shell (CTRL+SHIFT+T)",
    keys = {keys.leftCtrl, keys.leftShift, keys.t},
    f = function()
      _ENV.wm.addProcess("/rom/programs/shell.lua", {
        title = "Shell",
      }, true)
    end,
  },
  {
    name = "Open Lua (CTRL+SHIFT+L)",
    keys = {keys.leftCtrl, keys.leftShift, keys.l},
    f = function()
      _ENV.wm.addProcess("/rom/programs/lua.lua", {
        title = "Lua",
      }, true)
    end,
  },
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
    _, h = term.getSize()
  end

  if debounce == false then
    for _, v in pairs(hotkeys) do
      local ok = true

      for _, k in pairs(v.keys) do
        if heldKeys[k] ~= true then
          ok = false
          break
        end
      end

      local heldCount = 0

      for _, v in pairs(heldKeys) do
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