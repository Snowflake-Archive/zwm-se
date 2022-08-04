local wm = require(".lib.wm")
os.queueEvent("test")
local logger = wm.getSystemLogger()

logger:info("[HotkeyService] Hotkey service started")

while true do
  local f = fs.open("test2.lua", "w")
  f.write("infact running")
  f.close()
  sleep(1)
end