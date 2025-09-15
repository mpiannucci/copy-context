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
    -- disable_default_keymap = false, -- set to true to disable default keymaps
  },
  keys = {
    { "<leader>cf", mode = "n", desc = "Copy file context" },
    { "<leader>cv", mode = { "n", "v" }, desc = "Copy selection/line context" },
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

- `<leader>cf`: copies `@relative/path/to/file`
- `<leader>cv` in Visual/Select: copies selected lines (e.g. `#L5` or `#L5-10`)
- `<leader>cv` in Normal: copies current line (e.g. `#L5`)
- Command: `:CopyContext` (selection if present; otherwise file)

The plugin writes to the system clipboard (`+`) and the unnamed register (`"`). A small notification displays what was copied.

## Options

- `disable_default_keymap` (boolean, default `false`): if `true`, no mappings are created. Define your own, e.g.:

```lua
vim.keymap.set("n", "<leader>cf", function()
  require("copy-context").copy_file()
end, { desc = "Copy file context" })

vim.keymap.set({ "n", "v" }, "<leader>cv", function()
  require("copy-context").copy_visual_or_line()
end, { desc = "Copy selection/line context" })
```

## License

MIT — see [LICENSE](./LICENSE).
