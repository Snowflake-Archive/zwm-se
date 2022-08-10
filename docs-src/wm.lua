--- The window manager and it's functions.
-- @module[kind=core] WindowManager

local wm = {}

--- Gets the system's logger.
-- @return Logger The logger.
function wm.getSystemLogger() end

--- Kills a process with the specified ID.
-- @tparam number id The ID.
function wm.killProcess() end

--- Gets all running processes.
-- @return Process[] The processes.
function wm.getProcesses() end

--- Gets the size of the window manager.
-- @return number x The size in the X axis
-- @return number y The size in the Y axis
function wm.getSize() end

--- Creates a process
-- @tparam string|function The path/function to launch. Note that functions are not well supported.
-- @tparam ProcessOptions options The options for the program.
-- @tparam[opt] boolean focused Whether or not the process will be focused when it is started
-- @see ProcessOptions
function wm.addProcess() end

return wm