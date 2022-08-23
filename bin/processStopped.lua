if _ENV.wmProcessStopInfo then
  local scrollbox = require(".lib.ui.scrollbox")
  local button = require(".lib.ui.button")
  local focusableEventManager = require(".lib.ui.focusableEventManager")
  local strings = require("cc.strings")

  local focusableManager = focusableEventManager:new()
  local eventManager = require(".lib.events"):new()
  local w, h = term.getSize()

  local current = term.current()
  local errorInfoBox = scrollbox:new(2, 2, w - 2, h - 4, current, {y = true})
  local okay = button:new{
    x = w - 5, 
    y = h - 1, 
    text = "OK", 
    callback = function()
      _ENV.wm.killProcess(_ENV.wm.id)
    end,
  }

  local scrollboxTerm = errorInfoBox:getTerminal()

  _ENV.wm.setProcessTitle(_ENV.wm.id, "Crash Report")

  focusableManager:addButton(okay)
  focusableManager:inject(eventManager)
  errorInfoBox:addToEventManager(eventManager)
  
  local function render()
    w, h = term.getSize()

    okay:reposition(w - 5, h - 1)
    errorInfoBox:reposition(2, 2, w - 2, h - 4)
    current = term.current()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.gray)
    term.clear()

    local eText = ("An error occured in %s, and the process was stopped. The error, including it's stack traceback, is available below:"):format(_ENV.wmProcessStopInfo.name)
    local eTextLines = strings.wrap(eText, w - 4)
    scrollboxTerm.setBackgroundColor(colors.white)
    scrollboxTerm.setTextColor(colors.black)
    scrollboxTerm.clear()
    
    for i, v in pairs(eTextLines) do
      scrollboxTerm.setCursorPos(1, i)
      scrollboxTerm.write(v)
    end

    local error = _ENV.wmProcessStopInfo.error
    local errorLines = strings.wrap(error, w - 4)
    
    for i, v in pairs(errorLines) do
      scrollboxTerm.setCursorPos(1, i + #eTextLines + 1)
      scrollboxTerm.write(v)
    end

    local traceback = _ENV.wmProcessStopInfo.traceback
    local tracebackLines = strings.wrap(traceback, w - 4)
    
    for i, v in pairs(tracebackLines) do
      scrollboxTerm.setCursorPos(1, i + #eTextLines + #errorLines + 1)
      scrollboxTerm.write(v)
    end
    
    scrollbox:redraw()
    okay:render()
  end

  render()

  eventManager:addListener("term_resize", function()
    render()
  end)

  eventManager:listen()
end