-- Module imports
local events = require(".lib.events")
local util = require(".lib.util")
local file = require(".lib.file")
local logger = require(".lib.log")

local eventManager = events:new()

local native = term.current()
local w, h = term.getSize()
local buffer = window.create(term.current(), 1, 1, w, h)

local log = logger:new(true)

local processes = {}
local displayOrder = {}

local heldKeys = {}

local windowMovingState = {}

xpcall(function()
  local function redirect(process, e)
    if e[1] ~= "timer" then
      local se = ""

      for i, v in pairs(e) do
        se = se .. " " .. tostring(v)
      end

      logger:info("Event redirect to %s", se)
    end

    coroutine.resume(process.coroutine, unpack(e))
  end

  -- Functions

  local function renderProcess(p, idx, diso)
    if p.isService ~= true and p.visible == true then
      if not p.hideFrame then
        local color = p.focused and colors.cyan or colors.lightBlue

        paintutils.drawLine(p.x, p.y, p.x + p.w - 1, p.y, color)
        term.setTextColor(colors.white)
        term.setCursorPos(p.x, p.y)
        term.write(tostring (diso) .. "." .. tostring(idx) .. ">" .. p.title)

        term.setCursorPos(p.x + p.w - 3, p.y)
        term.setBackgroundColor(colors.red)
        term.setTextColor(colors.white)
        term.write(" x ")

        for i = 1, p.h do
          local _, line, lineB = buffer.getLine(p.y + i - 1)
          local use = line
          
          if p.hadBeenRenderedAt == nil then
            use = lineB
          end

          local bg = util.fromBlit(util.selectXfromBlit(p.x - 1, use))

          util.drawPixelCharacter(p.x - 1, p.y + i - 1, false, true, false, true, false, true, color, bg)
        end

        local _, _, line2 = buffer.getLine(p.y + p.h)
        util.drawPixelCharacter(p.x - 1, p.y + p.h, false, true, false, false, false, false, color, util.fromBlit(util.selectXfromBlit(p.x - 1, line2)))
        
        for i = 1, p.w do
          local bg = util.fromBlit(util.selectXfromBlit(p.x + i - 1, line2))
          util.drawPixelCharacter(p.x + i - 1, p.y + p.h, true, true, false, false, false, false, color, bg)
        end

        util.drawPixelCharacter(p.x + p.w, p.y + p.h, true, false, false, false, false, false, color, util.fromBlit(util.selectXfromBlit(p.x + p.w, line2)))

        for i = 1, p.h do
          local _, _, line3 = buffer.getLine(p.y + i - 1)
          local bg = util.fromBlit(util.selectXfromBlit(p.x + p.w, line3))
          util.drawPixelCharacter(p.x + p.w, p.y + i - 1, true, false, true, false, true, false, color, bg)
        end
      end

      p.hadBeenRenderedAt = true
      p.window.redraw()
    end
  end

  --- Renders all active processes.
  local function renderProcesses()
    term.redirect(buffer)
    for i = #displayOrder, 1, -1 do
      local v = displayOrder[i] -- display order index
      local p = processes[v] -- process
      if p then
        renderProcess(p, v, i)
      end
    end
  end

  local function killProcess(p, idx, diso)
    p.coroutine = nil
    processes[idx] = nil
    table.remove(displayOrder, diso)
    renderProcesses()
  end

  -- TODO: make this gracefully end a process, sending an "end" event to it, so the program can wrap up what it's doing / ask user to save, etc.
  -- the process respond with an "end-receive" to ensure it supports this functionality, and "end-ready" to indiciate it's ready to be removed.
  local function endProcess()

  end

  --- Creates a process
  local function addProcess(process, options, focused)
    local newProcess = {}

    newProcess.isService = options.isService

    if focused then
      for i, v in pairs(processes) do
        v.focused = false
      end
    end

    if options.isService ~= true then
      newProcess.w = options.w or 25
      newProcess.h = options.h or 10
      newProcess.x = options.x or 2
      newProcess.y = options.y or 2
      newProcess.title = options.title or (type(process) == "string" and fs.getName(process) or "Untitled")
      newProcess.isResizeable = options.isResizeable or true
      newProcess.hideFrame = options.hideFrame or false
      newProcess.visible = options.visible or true

      newProcess.focused = focused or false

      table.insert(displayOrder, 1, #processes + 1)

      newProcess.hideMaximize = options.hideMaximize or false
      newProcess.hideMinimize = options.hideMinimize or false
      
      local w = window.create(
        buffer, 
        newProcess.x, 
        newProcess.y, 
        newProcess.w, 
        newProcess.h, 
        newProcess.visible
      )

      if newProcess.hideFrame == false then
        w.reposition(newProcess.x, newProcess.y + 1, newProcess.w, newProcess.h - 1)
      end

      newProcess.window = w
    end

    if type(process) == "function" then
      newProcess.coroutine = coroutine.create(process)
    else
      newProcess.coroutine = coroutine.create(function()
        logger:info("Started process %s", process)
        local path = process

        xpcall(function()
          shell.run(path)
        end, function(err)
          logger:error("Process %s ended: \n%s %s", path, err, debug.traceback())
        end)
      end)
    end

    table.insert(processes, newProcess)
  end

  local function redirectEventsForMouse(p, e, idx, diso)
    if p.hideFrame then
      redirect(p, {e[1], e[2], e[3] - p.x, e[4] - p.y}) 
    else
      if e[4] == p.y then
        if e[3] >= p.x + p.w - 5 and e[3] <= p.x + p.w - 2 then
          killProcess(p, idx, diso)
        end
      else
        redirect(p, {e[1], e[2], e[3] - p.x + 1, e[4] - p.y}) 
      end
    end
  end

  addProcess("/bin/Services/ServiceWorker.lua", {isService = true})

  term.redirect(buffer)
  buffer.setBackgroundColor(colors.lightGray)
  buffer.clear()

  renderProcesses()

  parallel.waitForAny(
    function()
      -- Event loop
      while true do
        local e = {os.pullEvent()}
        local didHitMouse = false
        local gotFocusTarget = false

        local onCompleteDisplayOrder = {}

        for i, v in pairs(displayOrder) do
          onCompleteDisplayOrder[i] = v
        end

        if e[1] ~= "timer" then
          local se = ""

          for i, v in pairs(e) do
            se = se .. " " .. tostring(v)
          end

        end

        if e[1] == "term_resize" then
          local w, h = term.getSize()
          buffer.reposition(1, 1, w, h)
        elseif e[1] == "launch" then
          -- e[2]: id for message
          -- e[3]: path/func
          -- e[4]: options
          -- e[5]: focused
          logger:info("launch", e[3])
          addProcess(e[3], e[4], e[5])
          for i, v in pairs(processes) do
            coroutine.resume(v.coroutine, "launched", e[2])
          end
        elseif e[1] == "getSystemLogger" then
          for i, v in pairs(processes) do
            coroutine.resume(v.coroutine, "gotSystemLogger", logger)
          end
        end

        for i, v in pairs(processes) do
          if coroutine.status(v.coroutine) == "dead" then
            killProcess(v, i, i)
          end

          if v.isService and v.coroutine then
            coroutine.resume(v.coroutine, unpack(e))
          end
        end

        for i = 1, #displayOrder, 1 do
          local newOrder = i
          local o = displayOrder[i] -- display order index
          local v = processes[o] -- process

          if v then
            if e[1] ~= "timer" then
              logger:info("Process %d: %s", o, v.title)
            end

            term.redirect(v.window)

            if v.focused == true then
              if e[1]:match("^mouse_%a+") then
                if e[3] >= v.x and e[3] <= v.x + v.w and e[4] >= v.y and e[4] <= v.y + v.h then
                  redirectEventsForMouse(v, e, o, i)
                  didHitMouse = true
                  logger:info("Mouse hit done")
                end
              -- Did not match mouse
              else
                redirect(v, e)  
              end
            -- Focused == false
            else
              local canRedirect = true

              if p.isService == false and e[1] == "mouse_click" or e[1] == "mouse_drag" or e[1] == "mouse_scroll" or e[1] == "mouse_up" or e[1] == "paste" or e[1] == "key" or e[1] == "key_up" or e[1] == "char" then
                canRedirect = false
              end

              if e[1] == "mouse_click" and gotFocusTarget == false and didHitMouse == false then
                if e[3] >= v.x and e[3] <= v.x + v.w - 1 and e[4] >= v.y and e[4] <= v.y + v.h - 1 then
                  for i, v in pairs(processes) do
                    v.focused = false
                  end
                  v.focused = true
                  term.redirect(buffer)
                  redirectEventsForMouse(v, e, o, i)
                  term.redirect(v.window)
                  didHitMouse = true
                  gotFocusTarget = true

                  table.remove(onCompleteDisplayOrder, i)
                  table.insert(onCompleteDisplayOrder, 1, "")
                  onCompleteDisplayOrder[1] = o

                  logger:info("redirected to %d", o)
                else
                  coroutine.resume(v.coroutine)
                end
              else
                if canRedirect then
                  redirect(v, e)  
                else
                  coroutine.resume(v.coroutine)
                end
              end
            end
          end
        end

        term.redirect(buffer)

        if didHitMouse == false and e[1]:match("^mouse_%a+") then
          for i, v in pairs(processes) do
            if v.focused == true then
              v.focused = false
              break
            end
          end
        end

        eventManager:check(e)
        buffer.setBackgroundColor(colors.lightGray)
        buffer.clear()

        displayOrder = onCompleteDisplayOrder
        renderProcesses()
      end
    end,
    function()
      -- Buffer
      buffer.setVisible(false)
      term.redirect(buffer)
      local w, h = buffer.getSize()

      while true do
        for t = 0, 15 do
          native.setPaletteColor(2^t, buffer.getPaletteColor(2^t))
        end
        local cursorPos = {buffer.getCursorPos()}
        local cursorBlink = buffer.getCursorBlink()
        native.setCursorBlink(false)
        for t = 1, h do
          native.setCursorPos(1, t)
          native.blit(buffer.getLine(t))
        end
        native.setCursorBlink(cursorBlink)
        native.setCursorPos(table.unpack(cursorPos))
        sleep()
      end
    end
  )
end, function(err)
  term.redirect(native)
  term.setCursorPos(1, 1)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  local traceback = debug.traceback()

  log:critical("A critical error has occured, causing the window manager to crash.\n%s\n%s", err, traceback)

  if err ~= "Terminated" then
    local filename = "crash-" .. os.epoch("utc") .. ".log"
    log:dump("/crash/" .. filename)
  end
  
  print("The system has crashed!")
  print(err)
  if err == "Terminated" then
    print("The window manager was terminated. Due to this, a crash report was not saved.")
  else
    print("A detailed crash report, including traceback, has been saved to " .. filename)
  end
end)