-- TODO: make this work using the registry (e.g. disabling & enabling services)

local services = {
  "/bin/Services/HotkeyService.lua",
}

local wm = require(".lib.wm")
local logger = wm.getSystemLogger()

logger:info("[ServiceWorker] Service worker started")

for i, v in pairs(services) do
  logger:debug("[ServiceWorker] Starting service: " .. v)
  wm.launch(v, {isService = true})
  logger:info("[ServiceWorker] Started service %d of %d: %s", i, #services, v)
end

logger:info("[ServiceWorker] Service working done, goodbye!")