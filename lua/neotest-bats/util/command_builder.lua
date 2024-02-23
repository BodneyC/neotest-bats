---@class CommandBuilder
---@field _executable string BATS executable binary
---@field _path string path to BATS file
---@field _filter string string by which to filter tests
---@field _formatter string output format
---@field _use_file_as_executable boolean
local CommandBuilder = {
  _executable = "",
  _path = "",
  _filter = "",
  _formatter = "tap",
  _use_file_as_executable = false,

  new = function(self, use_file_as_executable)
    local o = { _use_file_as_executable = use_file_as_executable }
    setmetatable(o, self)
    self.__index = self
    return o
  end,
}

---@param self CommandBuilder
---@param executable string @executable bashunit executable binary
---@return CommandBuilder
function CommandBuilder.executable(self, file_path, executable)
  if self._use_file_as_executable then
    self._executable = file_path
  else
    self._executable = executable
  end
  return self
end

---@param self CommandBuilder
---@param path string @path to test file
---@return CommandBuilder
function CommandBuilder.path(self, path)
  self._path = path
  return self
end

---@param self CommandBuilder
---@param filter string @filter by test name
---@return CommandBuilder
function CommandBuilder.filter(self, filter)
  self._filter = filter
  return self
end

local function concat_tables(dst, src)
  for _, e in ipairs(src) do
    dst[#dst + 1] = e
  end
  return dst
end

---@param self CommandBuilder
---@return string @command to run
function CommandBuilder.build(self)
  local cmd = { self._executable }
  if not self._use_file_as_executable then
    table.insert(cmd, self._path)
  end
  if self._filter ~= "" then
    concat_tables(cmd, { "--filter", self._filter })
  end
  if self._formatter ~= "" then
    concat_tables(cmd, { "--formatter", self._formatter })
  end
  return table.concat(cmd, " ")
end

return CommandBuilder
