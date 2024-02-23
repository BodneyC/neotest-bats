local FileChecker = require("neotest-bats.core.file_checker")
local RootFinder = require("neotest-bats.core.root_finder")
local DirFilter = require("neotest-bats.core.dir_filter")
local PositionsDiscoverer = require("neotest-bats.core.positions_discoverer")
local SpecBuilder = require("neotest-bats.core.spec_builder")
local ResultBuilder = require("neotest-bats.core.result_builder")

---@class Adapter
---@field name string
Adapter = { name = "neotest-bats" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function Adapter.root(dir)
  return RootFinder.find(dir, Adapter.config)
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
---@return boolean
function Adapter.filter_dir(name, rel_path, root)
  return DirFilter.filter(name, rel_path, root, Adapter.config)
end

---@async
---@param file_path string
---@return boolean
function Adapter.is_test_file(file_path)
  return FileChecker.is_test_file(file_path, Adapter.config)
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function Adapter.discover_positions(file_path)
  return PositionsDiscoverer.discover_positions(file_path, Adapter.config)
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function Adapter.build_spec(args)
  return SpecBuilder.build_spec(args, Adapter.config)
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function Adapter.results(spec, result, tree)
  return ResultBuilder.build_results(spec, result, tree, Adapter.config)
end

---@class AdapterConfig
---@field file_include_patterns string[]
---@field file_exclude_patterns string[]
---@field dir_exclude_patterns string[]
---@field root_dir_indicators string[]
---@field executable string
---@field use_file_as_executable boolean
local default = {
  ---Patterns by which to filter files to include as tests
  ---Reasoning for default:
  ---There's no standard for this, some use `my-test-file.bats` and others
  --- `my-test-file.bats.sh` for filetype detection.
  ---Also seen `.bats.bash` and `.spec.bash`, hence why I've left it
  --- configurable.
  file_include_patterns = { ".bats.sh$", ".bats$" },
  ---Patterns by which to filter files to exclude as tests
  file_exclude_patterns = {},
  ---Patterns by which to filter directories to exclude as tests, note that
  --- these are matched against the path from the project root directory and
  --- are not absolute.
  ---Reasoning for default:
  ---`libs` is the standard place but I've seen them put in
  --- `tests/libs` so no `^`.
  ---`^bats/` is because I've also seen them in bats directories when you
  ---  perhaps already have a `libs` for another purpose.
  dir_exclude_patterns = { "libs/", "^bats/" },
  root_dir_indicators = { ".git", "lib" },
  ---Path to executable, the BATS test-runner
  executable = "bats",
  ---Whether to use the name of the file as the executable, i.e. that the path
  --- to BATS executable and any other options are given in the file's shebang
  use_file_as_executable = false,
  ---You can use comments (# @test) to indicate tests if you don't like the
  --- `@test "test" {}` syntax, this will enable that. I tried to do both at
  --- the same time and merge the trees but couldn't get it working :(
  ---If anyone else can, please raise a PR...
  use_comments_to_indicate_tests = false,
}

function Adapter.setup(opt)
  Adapter.config = vim.tbl_deep_extend("force", default, opt or {})
  return Adapter
end

return Adapter
