--- Logger
-- @moudle[kind=core] Logger
-- @author Marcus Wenzel

local logger = {}

local version = "1.0"

local lookup = {
  debug = "DBUG",
  info = "INFO",
  warning = "WARN",
  error = "ERRO",
  critical = "CRITICAL"
}

--- Creates a new logger.
-- @tparam boolean debug If debugging is enabled or not
-- @return table The logger
function logger:new(debug)
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
  if self.isDebug == false and type == "debug" then return end
  local fmsg = message

  if ({...})[1] then
    fmsg = string.format(message, ...)
  end

  line = ("[" .. (lookup[type] or type) .. "] " .. os.date("%X") .. ": " .. fmsg .. "\n")

  table.insert(self.lines, {
    type = type,
    message = fmsg,
    time = os.date("%X")
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
  self:log("debug", message, ...)
end

--- Logs a message as an Info message. Extra arguments are treated as string.format arguments.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:info(message, ...)
  self:log("info", message, ...)
end

--- Logs a message as a Warning. Extra arguments are treated as string.format arguments.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:warn(message, ...)
  self:log("warm", message, ...)
end

--- Logs a message as an Error. Extra arguments are treated as string.format arguments.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:error(message, ...)
  self:log("error", message, ...)
end

--- Logs a message as a Critcal Error. Extra arguments are treated as string.format arguments.
-- @tparam string message The message to log
-- @tparam any ... Extra arguments to pass to string.format
function logger:critical(message, ...)
  self:log("critical", message, ...)
end

--- Dumps logs.
-- @tparam string file The file to dump to
function logger:dump(file)
  self:info("Logs dumped to " .. file)
  local f = fs.open(file, "w")
  f.write(self.linesText)
  f.close()
end

return logger