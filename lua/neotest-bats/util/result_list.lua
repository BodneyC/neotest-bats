local exit_codes = { success = 0 }

local ResultList = {
  _results = {},

  new = function(self)
    self.__index = self
    return setmetatable({}, self)
  end,
}

function ResultList.add_successful_result(self, result)
  self._results[result.id] = { status = "passed" }
end

function ResultList.add_failed_result(self, result)
  self._results[result.id] = { status = "failed" }
end

function ResultList.add_skipped_result(self, result)
  self._results[result.id] = { status = "skipped" }
end

function ResultList.add_result_with_code(self, result, code)
  if code == exit_codes.success then
    self:add_successful_result(result)
  else
    self:add_failed_result(result)
  end
end

-- @returns boolean whether all results passed
function ResultList.are_all_passed(self)
  for _, v in pairs(self._results) do
    if v.status ~= "passed" then
      return false
    end
  end
  return true
end

--- @returns table<string, neotest.Result> copy of results
function ResultList.to_table(self)
  -- makes a copy
  local results = {}
  for id, v in pairs(self._results) do
    results[id] = v
  end

  return results
end

return ResultList
