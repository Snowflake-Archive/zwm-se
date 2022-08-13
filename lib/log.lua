--- A logger good enough for ComputerCraft.
-- @module[kind=core] Logger

local logger = {}

local expect = require("cc.expect").expect

local version = "1.1"

local lookup = {
  debug = "DBUG",
  info = "INFO",
  warning = "WARN",
  error = "ERROR",
  critical = "CRITICAL",
}

--- Creates a new logger.
-- @tparam boolean debug If debugging is enabled or not
-- @return table The logger
function logger:new(debug)
  expect(1, debug, "boolean", "nil")

  local o = {}
  setmetatable(o, self)
  self.__index = self

  self.lines = {}
  self.linesText = ""
  self.isDebug = debug == true

  local handle = fs.open("log.log", "w")
  handle.write("")
  handle.close()

  self:info("Logger started! Version: %s", version)

  return o
end

--- Logs a message.
-- @tparam string type The type of message to log (debug, info, warning, error, critical)
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:log(type, message, ...)
  expect(1, type, "string")
  expect(2, message, "string")
  
  if self.isDebug == false and type == "debug" then return end
  local fmsg = message

  if ({...})[1] then
    fmsg = string.format(message, ...)
  end

  local line = "[" .. (lookup[type] or type) .. "] " .. os.date("%X") .. ": " .. fmsg .. "\n"

  table.insert(self.lines, {
    type = type,
    message = fmsg,
    time = os.date("%X"),
  })

  local handle = fs.open("log.log", "a")
  handle.write(line)
  handle.close()

  self.linesText = self.linesText .. line
end

--- Logs a message as a Debug message. Extra arguments are treated as string.format arguments. If debugging is disabled when the logger was created, these will be ignored.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:debug(message, ...)
  expect(1, message, "string")

  self:log("debug", message, ...)
end

--- Logs a message as an Info message. Extra arguments are treated as string.format arguments.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:info(message, ...)
  expect(1, message, "string")

  self:log("info", message, ...)
end

--- Logs a message as a Warning. Extra arguments are treated as string.format arguments.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:warn(message, ...)
  expect(1, message, "string")

  self:log("warm", message, ...)
end

--- Logs a message as an Error. Extra arguments are treated as string.format arguments.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:error(message, ...)
  expect(1, message, "string")

  self:log("error", message, ...)
end

--- Logs a message as a Critcal Error. Extra arguments are treated as string.format arguments.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:critical(message, ...)
  expect(1, message, "string")

  self:log("critical", message, ...)
end

--- Dumps logs.
-- @tparam string file The file to dump to
function logger:dump(file)
  expect(1, file, "string")
  
  self:info("Logs dumped to " .. file)
  local f = fs.open(file, "w")
  f.write(self.linesText)
  f.close()
end

return logger