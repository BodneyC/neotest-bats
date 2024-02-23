local nio = require("nio")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local Tree = require("neotest.types").Tree

Pos = { child_failed = true } -- TODO: Set to false

local comment_based_query = [[
  (function_definition
     name: (word) @test.name
     body: (compound_statement
             . (comment) @first_comment)
     (#eq? @first_comment "# @test")
  ) @test.definition
]]

local annotation_based_query = [[
  (command
    name: (command_name) @test.start
    (#eq? @test.start "@test")
    argument: (string) @test.name
  )
  (command
    name: (command_name) @test.end
    (#eq? @test.end "}")
  )
]]

---@returns string[]
local function get_at_range(lines, node)
  local sr, sc, er, ec = node:range()
  assert(#lines >= er + 1, "end row (" .. er + 1 .. ") is more than #lines (" .. #lines .. ")")
  assert(
    #lines[sr + 1] >= sc + 1,
    "start col (" .. sc + 1 .. ") is more than #lines[" .. sr + 1 .. "] (" .. #lines[sr + 1] .. ")"
  )
  assert(
    #lines[er + 1] >= ec + 1,
    "start col (" .. ec + 1 .. ") is more than #lines[" .. er + 1 .. "] (" .. #lines[er + 1] .. ")"
  )
  local range = {}
  if sr == er then
    table.insert(range, string.sub(lines[sr + 1], sc + 1, ec))
  else
    table.insert(range, string.sub(lines[sr + 1], sc + 1, #lines[sr + 1]))
  end
  for i = sr + 2, er or #lines, 1 do
    table.insert(range, lines[i])
  end
  if sr ~= er then
    table.insert(range, string.sub(lines[er + 1], 1, ec))
  end
  return range
end

---@private
function Pos._build_list_of_positions(file_path, query_str)
  local content = lib.files.read(file_path)
  local lines = vim.split(content, "[\r]?\n", { trimempty = false })
  local root, lang = lib.treesitter.get_parse_root(file_path, content, {})
  local query = lib.treesitter.normalise_query(lang, query_str)
  local parsed = {
    {
      type = "file",
      path = file_path,
      name = nio.fn.fnamemodify(file_path, ":t"),
      id = file_path,
      range = { root:range() },
    },
  }
  for _, match, _ in query:iter_matches(root, content) do
    for id, node in pairs(match) do
      local cap_name = query.captures[id]
      if cap_name == "test.start" then
        table.insert(parsed, {
          id = "",
          type = "test",
          name = "",
          path = file_path,
          range = { node:range() },
        })
      elseif cap_name == "test.name" then
        local extracted = get_at_range(lines, node)
        assert(#extracted == 1, "multiple lines returned for test_name: " .. vim.inspect(extracted))
        local test_name = extracted[1]
        test_name = string.sub(test_name, 2, #test_name - 1)
        assert(parsed[#parsed].id == "", "id already set for: " .. vim.inspect(parsed[#parsed]))
        parsed[#parsed].id = file_path .. "::" .. test_name
        assert(parsed[#parsed].name == "", "name already set for: " .. vim.inspect(parsed[#parsed]))
        parsed[#parsed].name = test_name
      elseif cap_name == "test.end" then
        local ele_range = parsed[#parsed].range
        local range = { node:range() }
        ele_range[3] = range[3]
        ele_range[4] = range[4]
      end
    end
  end

  return Tree.from_list(parsed, function(pos)
    return pos.id
  end)
end

---@return Tree | nil
local function parse_positions_for_comment_tests(file_path, query)
  if Pos.child_failed or not lib.subprocess.enabled() then
    return Pos._build_list_of_positions(file_path, query)
  end

  local tree, err = lib.subprocess.call(
    "require('neotest-bats.core.positions_discoverer')._build_list_of_positions",
    { file_path, query, true }
  )

  if err then
    logger.error("Child process failed to parse, disabling suprocess usage")
    Pos.child_failed = true
    return Pos._build_list_of_positions(file_path, query)
  end
  return tree
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return Tree | nil
function Pos.discover_positions(file_path, config)
  if config.use_comments_to_indicate_tests then
    return lib.treesitter.parse_positions(file_path, comment_based_query)
  else
    return parse_positions_for_comment_tests(file_path, annotation_based_query)
  end
end

return Pos
