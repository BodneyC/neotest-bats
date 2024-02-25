<!-- markdownlint-disable MD013 -->

# Neotest-bats

A [BATS](https://github.com/bats-core/bats-core) adapter for [Neotest](https://github.com/nvim-neotest/neotest).

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

## How it Works

I think I understand why there isn't already a `neotest-bats`: for the `@test` command used by BATS primarily (there is a commented option) the Treesitter layout is a little messy, take the example:

```sh
@test "atest" {
  :
}
```

This will appear as:

```sh
command [3, 0] - [3, 16]
  name: command_name [3, 0] - [3, 5]
    word [3, 0] - [3, 5]
  argument: string [3, 6] - [3, 14]
    string_content [3, 7] - [3, 13]
  argument: word [3, 15] - [3, 16]
command [4, 2] - [4, 3]
  name: command_name [4, 2] - [4, 3]
    word [4, 2] - [4, 3]
command [5, 0] - [5, 1]
  name: command_name [5, 0] - [5, 1]
    word [5, 0] - [5, 1]
```

So, no `function_declaration`... `@test` is seen (correctly, mind you) as a command with the arguments: `"atest"` and `{`, then the body of the test is completely separate to that first line.

Using a simple Treesitter query to extract the `@test.name` is fine, but `@test.definition` is not - I tried to grab all nodes until a final "command" with just the text `}` in it but was unsuccessful.

The approach I went with used the following queries:

```clojure
(command
  name: (command_name) @test.start
  (#eq? @test.start "@test")
  argument: (string) @test.name
)
(command
  name: (command_name) @test.end
  (#eq? @test.end "}")
)
```

The first extracts the name and marks the start of the test, the second marks the end.

The test definition is then manually resolved between the two and the Neotest tree is generated from those blocks.

### Alternative

There is an alternative to the `@test` *command* and that's to use the [comment syntax](https://bats-core.readthedocs.io/en/stable/writing-tests.html#comment-syntax), so:

```sh
function atest { # @test
  :
}
```

Where `function_delaration` is found properly and the whole thing is much easier:

```clojure
(function_definition
   name: (word) @test.name
   body: (compound_statement
           . (comment) @first_comment)
   (#eq? @first_comment "# @test")
) @test.definition
```

One limitation that I couldn't be bothered to work out was that `#match?` doesn't play nice with at-signs (`@`) so the "one space after the comment marker" thing is mandatory currently, happy to accept fixes on this.

I tried to run both approaches and merge the trees but was again unsuccessful - one again, happy to accept fixes on it.

# Disclaimer

The project structure was pinched/adapted from [`neotest-bash`](https://github.com/rcasia/neotest-bash).
