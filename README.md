# copy-context

A Neovim plugin to copy a reference to the current file or selected lines in a format that AI agents can consume.

- File: `@path/to/file`
- Single line: `@path/to/file#L5`
- Line range: `@path/to/file#L5-10`

Paths resolve relative to the project git root when available, otherwise relative to the current working directory.

## Installation

### LazyVim
Add to your LazyVim plugin specs:

```lua
{
  "mpiannucci/copy-context",
  opts = {
    -- disable_default_keymap = false, -- set to true to disable <leader>cc
  },
  keys = {
    { "<leader>cc", mode = { "n", "v" }, desc = "Copy context reference" },
  },
}
```

### lazy.nvim

```lua
require("lazy").setup({
  {
    "mpiannucci/copy-context",
    -- optional configuration
    opts = {
      -- disable_default_keymap = true,
    },
  },
})
```

### packer.nvim

```lua
use({
  "mpiannucci/copy-context",
  config = function()
    require("copy-context").setup({
      -- disable_default_keymap = true,
    })
  end,
})
```

Note: For non-Lazy setups, the plugin auto-calls `setup()` with defaults, so adding an explicit `setup()` call is only necessary if you want to change options.

## Usage

- Normal mode: `<leader>cc` copies `@relative/path/to/file`
- Visual mode: select lines, then `<leader>cc` copies with line(s) (e.g. `#L5` or `#L5-10`)
- Command: `:CopyContext`

The plugin writes to the system clipboard (`+`) and the unnamed register (`"`). A small notification displays what was copied.

## Options

- `disable_default_keymap` (boolean, default `false`): if `true`, no mappings are created. Define your own, e.g.:

```lua
vim.keymap.set({ "n", "v" }, "<leader>cx", function()
  require("copy-context").copy_context()
end, { desc = "Copy context reference" })
```

## License

MIT — see [LICENSE](./LICENSE).
