DirFilter = {}

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@param config AdapterConfig Plugin configuration
---@return boolean
---@diagnostic disable-next-line: unused-local
function DirFilter.filter(name, rel_path, root, config)
  local excluded = false
  for _, pattern in ipairs(config.dir_exclude_patterns) do
    excluded = rel_path:match(pattern) or excluded
  end
  return not excluded
end

return DirFilter
