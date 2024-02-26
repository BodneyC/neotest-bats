local root_finder = require('neotest-bats.core.root_finder')
local CommandBuilder = require('neotest-bats.util.command_builder')

local SpecBuilder = {}

---@param args neotest.types.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function SpecBuilder.build_spec(args, config)
  local tree = args.tree
  local tree_data = tree:data()
  local path = tree_data.path
  local root = root_finder.find(tree_data.path, config)

  local commands = {}
  for _, node in tree:iter_nodes() do
    local node_data = node:data()
    local command
    if node_data.type == 'file' then
      command = CommandBuilder:new(config.use_file_as_executable)
        :executable(node_data.path, config.executable)
        :path(path)
    elseif node_data.type == 'test' then
      command = CommandBuilder:new(config.use_file_as_executable)
        :filter(node_data.name)
        :executable(node_data.path, config.executable)
        :path(path)
    else
      return nil
    end

    commands[#commands + 1] = {
      command = command:build(),
      cwd = root,
      context = {
        path = path,
        name = node_data.name,
      },
    }
  end

  return commands
end

return SpecBuilder
