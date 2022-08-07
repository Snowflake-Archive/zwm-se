-- TODO: make this work using the registry (e.g. disabling & enabling services)

local services = {
  "/bin/Services/HotkeyService.lua",
}

local logger = wm.getSystemLogger()

logger:info("[ServiceWorker] Service worker started")

for i, v in pairs(services) do
  logger:info("[ServiceWorker] Starting service: " .. v)
  _ENV.wm.addProcess(v, {isService = true})
  logger:info("[ServiceWorker] Started service %d of %d: %s", i, #services, v)
end

logger:info("[ServiceWorker] Service working done, goodbye!")