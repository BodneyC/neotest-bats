local ResultList = require("neotest-bats.util.result_list")
local FileChecker = require("neotest-bats.core.file_checker")

ResultBuilder = {}

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@param config AdapterConfig
---@return table<string, neotest.Result>
function ResultBuilder.build_results(spec, result, tree, config)
  local results = ResultList:new()

  local is_file = FileChecker.is_test_file(spec.context.name, config)

  -- TODO: We run tests running one command per test funtion so we do not
  --        expect to find files as spec.context.name
  if not is_file then
    for _, node in tree:iter_nodes() do
      local node_data = node:data()
      if node_data.name == spec.context.name then
        results:add_result_with_code(node_data, result.code)
      end
    end
  end

  return results:to_table()
end

return ResultBuilder
