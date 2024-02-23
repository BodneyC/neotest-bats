<!-- markdownlint-disable MD013 -->

# Neotest-bats

## Installation

[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) is a dependency.

*Note*: The Bash parser is required for this, install with `:TSInstall bash`

```lua
require('lazy').setup({
  'BodneyC/neotest-bats'
})
```

## Configuration

This is loading the adapter in Neotest and all the plugin's default configuration values.

```lua
require("neotest").setup({
  adapters = {
    require("neotest-bats").setup {
      -- Patterns by which to filter files to include as tests
      -- Reasoning for defaults:
      -- There's no standard for this, some use `my-test-file.bats` and others
      --  `my-test-file.bats.sh` for filetype detection.
      -- Also seen `.bats.bash` and `.spec.bash`, hence why I've left it
      --  configurable.
      file_include_patterns = { '.bats.sh$', '.bats$' },
      -- Patterns by which to filter files to exclude as tests
      file_exclude_patterns = {},
      -- Patterns by which to filter directories to exclude as tests, note that
      --  these are matched against the path from the project root directory and
      --  are not absolute.
      -- Reasoning for defaults:
      -- `libs` is the standard place but I've seen them put in
      --  `tests/libs` so no `^`.
      -- `^bats/` is because I've also seen them in bats directories when you
      --   perhaps already have a `libs` for another purpose.
      dir_exclude_patterns = { 'libs/', '^bats/' },
      root_dir_indicators = { '.git', 'lib' },
      -- Path to executable, the BATS test-runner
      executable = { 'bats' },
      -- Whether to use the name of the file as the executable, i.e. that the path
      --  to BATS executable and any other options are given in the file's shebang
      use_file_as_executable = false,
      ---You can use comments (# @test) to indicate tests if you don't like the
      --- `@test "test" {}` syntax, this will enable that. I tried to do both at
      --- the same time and merge the trees but couldn't get it working :(
      ---If anyone else can, please raise a PR...
      use_comments_to_indicate_tests = false,
    }
  }
})
```

# Disclaimer

Much of this is pinched/adapted from [`neotest-bash`](https://github.com/rcasia/neotest-bash).
