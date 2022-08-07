-- Module imports
local util = require(".lib.util")
local file = require(".lib.file")
local logger = require(".lib.log")
local registry = require(".lib.registry")

local makePackage = dofile("rom/modules/main/cc/require.lua").make

local log = logger:new(false)
local native = term.current()
local w, h = term.getSize()
local buffer = window.create(term.current(), 1, 1, w, h)

local processes = {}
local displayOrder = {}

local windowRenderer = require(".bin.WindowManagerModules.WindowRenderer"):new(logger, buffer, displayOrder, processes)
local windowEvents = require(".bin.WindowManagerModules.WindowEvents"):new(logger, buffer)
local menu = require(".bin.WindowManagerModules.Menu"):new(logger, buffer)

local nextProcessId = 0

xpcall(function()
  -- Functions

  local wm = {}

  --- Gets the system's logger.
  -- @return Logger The logger.
  function wm.getSystemLogger()
    return log
  end

  --- Kills a process with the specified ID.
  -- @tparam number id The ID.
  function wm.killProcess(idx)
    local p = processes[idx]
    p.coroutine = nil
    processes[idx] = nil

    for i, v in pairs(displayOrder) do
      if v == p then
        table.remove(displayOrder, i)
        break
      end
    end

    windowRenderer:renderProcesses(processes, displayOrder)
  end

  --- Gets all running processes.
  -- @return Process[] The processes.
  function wm.getProcesses()
    return processes
  end

  --- Gets the size of the window manager.
  -- @return number x The size in the X axis
  -- @return number y The size in the Y axis
  function wm.getSize()
    return buffer.getSize()
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
  -- @tparam string|function The path/function to launch. Note that functions are not well supported.
  -- @tparam Options options The options for the program.
  -- @tparam[opt] boolean focused Whether or not the process will be focused when it is started
  function wm.addProcess(process, options, focused)
    local newProcess = {}

    logger:debug("Starting process %s", tostring(process))
    newProcess.isService = options.isService == true

    if focused then
      for i, v in pairs(processes) do
        v.focused = false
      end
    end

    if type(process) == "string" then
      newProcess.startedFrom = process
    end

    if options.isService ~= true then
      if options.isCentered then
        options.x = math.floor((w / 2 - (options.w or 25) / 2) + 0.5)
        options.y = math.floor((h / 2 - (options.h or 10) / 2) + 0.5)
      end

      newProcess.w = options.w or 25
      newProcess.h = options.h or 10
      newProcess.x = options.x or 2
      newProcess.y = options.y or 2
      newProcess.title = (options.title or (type(process) == "string" and fs.getName(process) or "Untitled"))
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
        local endedGracefully = false

        xpcall(function()
          if fs.exists(path) then
            local f = fs.open(path, "r")
            local data = f.readAll()
            f.close()

            local f = load(data, "in " .. (newProcess.title or process))

            if f then
              local env = _ENV
              env.shell = shell
              env.require, env.package = makePackage(env, "/")
              env.wm = wm
              env.wm.id = nextProcessId - 1

              if options.env then
                for i, v in pairs(options.env) do
                  if not env[i] then
                    env[i] = v
                  end
                end
              end

              setfenv(f, env)
              f()
              endedGracefully = true
            end
          else
            wm.addProcess("/bin/Prompts/Error.lua", {
              isCentered = true,
              w = 32,
              h = 9,
              hideMinimize = true,
              hideMaximize = true,
              title = "Error",
              env = {
                errorText = "The requested path, " .. process .. ", does not exist."
              }
            })
          end
        end, function(stop)
          if endedGracefully == false then
            local trace = debug.traceback()
            logger:error("Process %s ended: \n%s %s", path, stop, trace)
            wm.addProcess("/bin/processStopped.lua", {
              env = {
                wmProcessStopInfo = {
                  name = newProcess.title or "",
                  error = stop,
                  traceback = trace
                }
              },
              isCentered = true,
              w = 30,
              h = 14,
              title = "Crash Report",
              hideMaximize = true,
              hideMinimize = true
            }, true)
          end
        end)
      end)
    end

    processes[nextProcessId] = newProcess
    nextProcessId = nextProcessId + 1
    return nextProcessId - 1
  end

  wm.addProcess("/bin/Services/ServiceWorker.lua", {isService = true})

  term.redirect(buffer)
  buffer.setBackgroundColor(colors.lightGray)
  buffer.clear()

  windowRenderer:renderProcesses(processes, displayOrder)
  menu:render(processes)

  parallel.waitForAny(
    function()
      -- Event loop
      while true do
        local e = {os.pullEvent()}

        -- == Events == --

        if e[1] == "term_resize" then
          local nW, nH = native.getSize()
          w, h = nW, nH
          buffer.reposition(1, 1, w, h)
          logger:info("Resized to %d x %d", w, h)
        elseif e[1] == "launchProgram" then
          -- e[2]: id for message
          -- e[3]: path/func
          -- e[4]: options
          -- e[5]: focused
          local id = wm.addProcess(e[3], e[4], e[5])
          table.insert(displayOrder, 1, id)

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
        elseif e[1] == "focusProcess" then
          -- e[2]: id of process to focus
          for i, v in pairs(processes) do
            v.focused = false
            if i == e[2] then
              v.focused = true
            end
          end

          table.remove(displayOrder, i)
          table.insert(displayOrder, 1, "")
          displayOrder[1] = e[2]
        elseif e[1] == "killProcess" then
          -- e[2]: id of process to kill
          wm.killProcess(e[2])
        end

        -- Dead Process Checking
        for i, v in pairs(processes) do
          if coroutine.status(v.coroutine) == "dead" then
            wm.killProcess(i)
          end
      
          if v.isService and v.coroutine then
            coroutine.resume(v.coroutine, unpack(e))
          end
        end

        displayOrder = windowEvents:fire(e, processes, displayOrder)
        menu:fire(e)

        -- == Rendering == --

        local anyFocused = false
        for i, v in pairs(processes) do
          if v.focused then
            anyFocused = true
          end
        end

        buffer.setBackgroundColor(registry.readKey("machine", "Appearance.BackgroundColor"))
        buffer.clear()

        ensureDisplayOrder()
        windowRenderer:renderProcesses(processes, displayOrder)
        local cX, cY = term.getCursorPos()

        menu:render(processes)

        term.setCursorPos(cX, cY)

        if anyFocused == false then
          term.setCursorBlink(false)
        end
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
        local color = buffer.getTextColor()
        native.setCursorBlink(false)
        for t = 1, h do
          native.setCursorPos(1, t)
          native.blit(buffer.getLine(t))
        end
        native.setCursorBlink(cursorBlink)
        native.setCursorPos(table.unpack(cursorPos))
        native.setTextColor(color)
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