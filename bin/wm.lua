-- Module imports
local events = require(".lib.events")
local util = require(".lib.util")
local file = require(".lib.file")
local logger = require(".lib.log")
local registry = require(".lib.registry")

local eventManager = events:new()

local native = term.current()
local w, h = term.getSize()
local buffer = window.create(term.current(), 1, 1, w, h)

local log = logger:new(false)

local processes = {}
local displayOrder = {}

local heldKeys = {}

local windowDraggingState
local windowResizeState
local backgroundLayers = {}
local renderMenu = false

local frameTime = 0

xpcall(function()
  local function redirect(process, e)
    if e[1] ~= "timer" then
      local se = ""

      for i, v in pairs(e) do
        se = se .. " " .. tostring(v)
      end
    end

    coroutine.resume(process.coroutine, unpack(e))
  end

  -- Functions

  local function renderProcess(p, idx, diso)
    if p.isService ~= true and p.visible == true then
      if not p.hideFrame then
        local color = p.focused and registry.readKey("machine", "Appearance.WindowFocused") or registry.readKey("machine", "Appearance.WindowUnfocused")

        paintutils.drawLine(p.x, p.y, p.x + p.w - 1, p.y, color)
        term.setTextColor(registry.readKey("machine", "Appearance.TitlebarText"))
        term.setCursorPos(p.x, p.y)
        term.write(tostring (diso) .. "." .. tostring(idx) .. ">" .. p.title)

        term.setCursorPos(p.x + p.w - 3, p.y)
        term.setBackgroundColor(registry.readKey("machine", "Appearance.CloseButton"))
        term.setTextColor(registry.readKey("machine", "Appearance.CloseButtonText"))
        term.write(" x ")

        local nextButtonRenderAt = p.x + p.w - 6

        term.setBackgroundColor(registry.readKey("machine", "Appearance.ControlButton"))
        term.setTextColor(registry.readKey("machine", "Appearance.ControlButtonText"))

        if p.hideMaximize == false then
          term.setCursorPos(nextButtonRenderAt, p.y)
          term.write(" " .. (p.isMaxamized and "-" or "+") .. " ")
          nextButtonRenderAt = nextButtonRenderAt - 3
        end

        if p.hideMinimize == false then
          term.setCursorPos(nextButtonRenderAt, p.y)
          term.write(" \31 ")
          nextButtonRenderAt = nextButtonRenderAt - 3
        end

        if p.x >= 2 then
          for i = 1, p.h do
            if p.y + i - 1 <= h then
              local _, lineA, lineB = buffer.getLine(p.y + i - 1)

              local use = util.fromBlit(util.selectXfromBlit(p.x - 1, lineB))

              if backgroundLayers[p.y + i - 1] and backgroundLayers[p.y + i - 1][p.x] then
                use = backgroundLayers[p.y + i - 1][p.x]
              else
                if backgroundLayers[p.y + i - 1] == nil then
                  backgroundLayers[p.y + i - 1] = {}
                end

                backgroundLayers[p.y + i - 1][p.x] = use
              end
              
              util.drawPixelCharacter(p.x - 1, p.y + i - 1, false, true, false, true, false, true, color, use)
            end
          end

         
          if p.y + p.h <= h then
            local _, _, line2 = buffer.getLine(p.y + p.h)
            util.drawPixelCharacter(p.x - 1, p.y + p.h, false, true, false, false, false, false, color, util.fromBlit(util.selectXfromBlit(p.x - 1, line2)))
          end
        end

        if p.y + p.h <= h then
          local _, _, line2 = buffer.getLine(p.y + p.h)
          for i = 1, p.w do
            if p.x + i - 1 <= w and p.x + i - 1 >= 1 then
              local bg = util.fromBlit(util.selectXfromBlit(p.x + i - 1, line2))
              util.drawPixelCharacter(p.x + i - 1, p.y + p.h, true, true, false, false, false, false, color, bg)
            end
          end

          
          if p.x + p.w <= w then
            util.drawPixelCharacter(p.x + p.w, p.y + p.h, true, false, false, false, false, false, color, util.fromBlit(util.selectXfromBlit(p.x + p.w, line2)))
          end
        end

        if p.x + p.w <= w then
          for i = 1, p.h do
            if p.y + i - 1 <= h then
              local _, _, line3 = buffer.getLine(p.y + i - 1)
              local bg = util.fromBlit(util.selectXfromBlit(p.x + p.w, line3))
              util.drawPixelCharacter(p.x + p.w, p.y + i - 1, true, false, true, false, true, false, color, bg)

              if backgroundLayers[p.y + i - 1] == nil then
                backgroundLayers[p.y + i - 1] = {}
              end

              backgroundLayers[p.y + i - 1][p.x + p.w + 1] = color
            end
          end
        end
      end

      p.hadBeenRenderedAt = true
      term.redirect(p.window)
      coroutine.resume(p.coroutine)
      p.window.redraw()
      term.redirect(buffer)
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

  local function renderMenubar()
    local oldX, oldY = term.getCursorPos()
    logger:info("Render menubar")
    buffer.setCursorPos(2, h)
    term.setBackgroundColor(colors.gray)
    buffer.clearLine()
    buffer.write("+")

    local time = os.time("ingame")
    local timeString = textutils.formatTime(time, true)
    term.setCursorPos(w - #timeString, h)
    term.write(timeString)

    util.drawPixelCharacter(w, h, false, true, false, true, false, true, colors.black, colors.gray)

    term.setCursorPos(oldX, oldY)
  end

  -- TODO: make this gracefully end a process, sending an "end" event to it, so the program can wrap up what it's doing / ask user to save, etc.
  -- the process respond with an "end-receive" to ensure it supports this functionality, and "end-ready" to indiciate it's ready to be removed.
  local function endProcess()

  end

  local function ensureDisplayOrder()
    for i, v in pairs(processes) do
      local hasDisplayOrder = false

      for k, j in pairs(displayOrder) do
        if j == i then
          if hasDisplayOrder == true then
            table.remove(displayOrder, k)
          end
          hasDisplayOrder = true
        end
      end

      if hasDisplayOrder == false and v.isService ~= true and v.visible == true then
        table.insert(displayOrder, i)
      end
    end
  end

  --- Creates a process
  local function addProcess(process, options, focused)
    local newProcess = {}

    logger:debug("Starting process %s", tostring(process))
    newProcess.isService = options.isService == true

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
      newProcess.isResizeable = options.isResizeable == true or options.isResizeable == nil
      newProcess.hideFrame = options.hideFrame or false
      newProcess.visible = options.visible or true

      newProcess.focused = focused or false

      table.insert(displayOrder, 1, #processes + 1)

      newProcess.hideMaximize = options.hideMaximize or false
      newProcess.hideMinimize = options.hideMinimize or false

      newProcess.isMaxamized = false

      local w

      if newProcess.hideFrame == true then 
        w = window.create(
          buffer, 
          newProcess.x, 
          newProcess.y, 
          newProcess.w, 
          newProcess.h, 
          newProcess.visible
        )
      else
        w = window.create(
          buffer, 
          newProcess.x, 
          newProcess.y + 1, 
          newProcess.w, 
          newProcess.h - 1, 
          newProcess.visible
        )
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
    return #processes
  end

  local function windowDrag(e)
    if windowDraggingState then
      local p = processes[windowDraggingState.idx]

      local newX = e[3]
      local newY = e[4]
      local deltaX = newX - windowDraggingState.x
      local deltaY = newY - windowDraggingState.y
      p.x = p.x + deltaX
      p.y = p.y + deltaY

      if p.hideFrame == true then
        p.window.reposition(p.x, p.y)
      else
        p.window.reposition(p.x, p.y + 1)
      end

      windowDraggingState.x = newX
      windowDraggingState.y = newY
    end

    if windowResizeState and e[2] == 2 then
      local p = processes[windowResizeState.idx]
      local newX = e[3]
      local newY = e[4]
      local deltaX = newX - windowResizeState.x
      local deltaY = newY - windowResizeState.y

      if p.w + deltaX <= 0 or p.h + deltaY <= 1 then
        windowResizeState = nil
        return
      end
      p.w = p.w + deltaX
      p.h = p.h + deltaY

      if p.hideFrame == true then
        p.window.reposition(p.x, p.y, p.w, p.h)
      else
        p.window.reposition(p.x, p.y + 1, p.w, p.h - 1)
      end
    end
  end

  local function redirectEventsForMouse(p, e, idx, diso)
    if p.hideFrame then
      redirect(p, {e[1], e[2], e[3] - p.x, e[4] - p.y}) 
    else
      if e[4] == p.y then
        if e[1] == "mouse_click" then
          if e[3] >= p.x + p.w - 3 and e[3] <= p.x + p.w - 1 then
            killProcess(p, idx, diso)
          elseif e[3] >= p.x + p.w - 6 and e[3] <= p.x + p.w - 4 then
            if p.hideMaximize == true and p.hideMinimize == true then
              return
            elseif p.hideMaximize == true then

            else
              p.isMaxamized = not p.isMaxamized

              if p.isMaxamized then
                p.w_orig = p.w
                p.h_orig = p.h
                p.x_orig = p.x
                p.y_orig = p.y

                p.w = w
                p.h = h - 1
                p.x = 1
                p.y = 2
                p.window.reposition(p.x, p.y + 1, p.w, p.h - 1)
              else
                p.w = p.w_orig
                p.h = p.h_orig
                p.x = p.x_orig
                p.y = p.y_orig
                p.window.reposition(p.x, p.y + 1, p.w, p.h - 1)
              end
            end
          elseif p.isMaxamized == false then
            windowDraggingState = {
              x = e[3],
              y = e[4],
              idx = idx,
            }
          end
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

        local eventStart = os.epoch("utc")

        local didHitMouse = false
        local gotFocusTarget = false
        local anyFocused = false

        local onCompleteDisplayOrder = {}

        for i, v in pairs(displayOrder) do
          onCompleteDisplayOrder[i] = v
        end

        if e[1] ~= "timer" then
          local se = ""

          for i, v in pairs(e) do
            se = se .. " " .. tostring(v)
          end

          logger:debug("Event: %s", se)
        end

        if e[1] == "term_resize" then
          local nW, nH = native.getSize()
          w, h = nW, nH
          buffer.reposition(1, 1, w, h)
          logger:info("Resized to %d x %d", w, h)
        elseif e[1] == "mouse_up" then
          if windowDraggingState then 
            windowDraggingState = nil
          end

          windowResizeState = nil
        elseif e[1] == "mouse_drag" then
          if windowDraggingState or windowResizeState then
            windowDrag(e)
          end
        elseif e[1] == "launchProgram" then
          -- e[2]: id for message
          -- e[3]: path/func
          -- e[4]: options
          -- e[5]: focused
          local id = addProcess(e[3], e[4], e[5])
          table.insert(onCompleteDisplayOrder, 1, id)
          for i, v in pairs(processes) do
            if v.window then
              term.redirect(v.window)
            end

            coroutine.resume(v.coroutine, "launched", e[2])
          end
        elseif e[1] == "getSystemLogger" then
          for i, v in pairs(processes) do
            if v.window then
              term.redirect(v.window)
            end

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

          if v and v.isService == false then
            if e[1] ~= "timer" then
              logger:debug("Process %d: %s", o, v.title)
            end

            term.redirect(v.window)

            if v.focused == true then
              anyFocused = true
              if e[1]:match("^mouse_%a+") then
                if e[3] >= v.x and e[3] <= v.x + v.w - 1 and e[4] >= v.y and e[4] <= v.y + v.h - 1 then
                  redirectEventsForMouse(v, e, o, i)
                  didHitMouse = true
                elseif e[2] == 2 and e[3] == v.x + v.w and e[4] == v.y + v.h and v.isResizeable == true and v.isMaxamized == false then
                  didHitMouse = true
                  windowResizeState = {
                    x = e[3],
                    y = e[4],
                    idx = o,
                  }
                end
              -- Did not match mouse
              else
                redirect(v, e)  
              end
            -- Focused == false
            else
              local canRedirect = true

              if e[1] == "mouse_click" or e[1] == "mouse_drag" or e[1] == "mouse_scroll" or e[1] == "mouse_up" or e[1] == "paste" or e[1] == "key" or e[1] == "key_up" or e[1] == "char" then
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

                  anyFocused = true
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

        local eventTime = os.epoch("utc") - eventStart

        local renderStart = os.epoch("utc")
        eventManager:check(e)
        backgroundLayers = {}
        buffer.setBackgroundColor(registry.readKey("machine", "Appearance.BackgroundColor"))
        buffer.clear()

        local versionName = registry.readKey("machine", "SystemVersionName")

        local processCount = 0
        local serviceCount = 0
        for i, v in pairs(processes) do
          if v.isService == true then
            serviceCount = serviceCount + 1
          end
          processCount = processCount + 1
        end

        local str1 = versionName
        local str2 =  "ft " .. tostring(frameTime) .. "ms et " .. tostring(eventTime) .. " ms " .. tostring(processCount) .. " proc " .. tostring(serviceCount) .. " srv"

        if anyFocused == false then
          term.setCursorBlink(false)
          str2 = str2 .. " [idle]"
        end

        local w, h = buffer.getSize()
        buffer.setCursorPos(w - #str1 + 1, h - 1)
        term.setTextColor(colors.white)
        term.write(str1)
        buffer.setCursorPos(w - #str2 + 1, h - 2)
        term.write(str2)

        displayOrder = onCompleteDisplayOrder
        ensureDisplayOrder()
        renderProcesses()

        if anyFocused == false then
          term.setCursorBlink(false)
        end

        renderMenubar()

        frameTime = os.epoch("utc") - renderStart
      end
    end,
    function()
      -- Buffer
      buffer.setVisible(false)
      term.redirect(buffer)

      while true do
        local w, h = buffer.getSize()

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
  local filename

  log:critical("A critical error has occured, causing the window manager to crash.\n%s\n%s", err, traceback)

  local so, se

  if err ~= "Terminated" then
    local so, se = pcall(function()
      filename = "crash-" .. os.date("%m-%d-%y_%H-%M-%S") .. ".log"
      log:dump("/" .. filename)
    end)
  end
  
  print("The system has crashed!")
  print(err)
  if err == "Terminated" then
    print("The window manager was terminated. Due to this, a crash report was not saved.")
  else
    if so == false then
      print("Additionally, an error occured while trying to save the crash report. Thus, the crash report was not be saved.")
      print(se)
    else
      print("A detailed crash report, including traceback, has been saved to", filename)
    end
  end
end)