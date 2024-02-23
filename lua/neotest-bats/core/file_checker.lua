FileChecker = {}

---@async
---@param file_path string
---@param config AdapterConfig
---@return boolean
function FileChecker.is_test_file(file_path, config)
  local included = false
  for _, pattern in ipairs(config.file_include_patterns) do
    included = file_path:match(pattern) or included
  end
  local excluded = false
  for _, pattern in ipairs(config.file_exclude_patterns) do
    excluded = file_path:match(pattern) or excluded
  end
  return included and not excluded
end

return FileChecker
