local lib = require('neotest.lib')

RootFinder = {}

---@async
---@param dir string
---@param config AdapterConfig
---@return string | nil
function RootFinder.find(dir, config)
  for _, matcher in ipairs(config.root_dir_indicators) do
    local root = lib.files.match_root_pattern(matcher)(dir)
    if root then
      return root
    end
  end
  return nil
end

return RootFinder
