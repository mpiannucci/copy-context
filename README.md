# copy-context

A Neovim plugin to copy a reference to the current file or selected lines in a format that AI agents can consume.

- File: `@path/to/file`
- Single line: `@path/to/file#L5`
- Line range: `@path/to/file#L5-10`
- GitHub permalink: `https://github.com/user/repo/blob/commit/path/to/file#L5-L10`

Paths resolve relative to the project git root when available, otherwise relative to the current working directory.

## Installation

### LazyVim

#### Default configuration (uses `<leader>cf` and `<leader>cs`)
```lua
{
  "mpiannucci/copy-context",
}
```

#### With custom keybindings (disable defaults and define your own)
```lua
{
  "mpiannucci/copy-context",
  opts = {
    disable_default_keymap = true,
  },
  keys = {
    { "<leader>cY", "<cmd>CopyFileContext<cr>", mode = "n", desc = "Copy file context" },
    { "<leader>cy", "<cmd>CopyLineContext<cr>", mode = { "n", "v" }, desc = "Copy selection/line context" },
    { "<leader>cgy", "<cmd>CopyGitHubPermalink<cr>", mode = { "n", "v" }, desc = "Copy GitHub permalink" },
    { "<leader>cgY", "<cmd>CopyGitHubFile<cr>", mode = "n", desc = "Copy GitHub file link" },
  },
}
```

#### Keep defaults and add additional keybindings
```lua
{
  "mpiannucci/copy-context",
  keys = {
    { "<leader>cf", "<cmd>CopyFileContext<cr>", mode = "n", desc = "Copy file context" },
    { "<leader>cs", "<cmd>CopyLineContext<cr>", mode = { "n", "v" }, desc = "Copy selection/line context" },
    -- Add your additional keybindings here
    { "<leader>cY", "<cmd>CopyFileContext<cr>", mode = "n", desc = "Copy file context (alt)" },
    { "<leader>cy", "<cmd>CopyLineContext<cr>", mode = { "n", "v" }, desc = "Copy selection/line context (alt)" },
    { "<leader>cgy", "<cmd>CopyGitHubPermalink<cr>", mode = { "n", "v" }, desc = "Copy GitHub permalink" },
    { "<leader>cgY", "<cmd>CopyGitHubFile<cr>", mode = "n", desc = "Copy GitHub file link" },
  },
}
```

### lazy.nvim

#### Default configuration
```lua
require("lazy").setup({
  {
    "mpiannucci/copy-context",
  },
})
```

#### With custom keybindings
```lua
require("lazy").setup({
  {
    "mpiannucci/copy-context",
    opts = {
      disable_default_keymap = true,
    },
    config = function()
      require("copy-context").setup({ disable_default_keymap = true })

      -- Define your custom keybindings
      vim.keymap.set("n", "<leader>cY", "<cmd>CopyFileContext<cr>", { desc = "Copy file context" })
      vim.keymap.set({ "n", "v" }, "<leader>cy", "<cmd>CopyLineContext<cr>", { desc = "Copy selection/line context" })
      vim.keymap.set({ "n", "v" }, "<leader>cgy", "<cmd>CopyGitHubPermalink<cr>", { desc = "Copy GitHub permalink" })
      vim.keymap.set("n", "<leader>cgY", "<cmd>CopyGitHubFile<cr>", { desc = "Copy GitHub file link" })
    end,
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
- `<leader>cs` in Visual/Select: copies selected lines (e.g. `#L5` or `#L5-10`)
- `<leader>cs` in Normal: copies current line (e.g. `#L5`)
- `<leader>cgY`: copies GitHub file link (e.g. `https://github.com/user/repo/blob/commit/file`)
- `<leader>cgy`: copies GitHub permalink with lines (e.g. `https://github.com/user/repo/blob/commit/file#L5-L10`)
- Commands:
  - `:CopyContext` (selection if present; otherwise file)
  - `:CopyFileContext` (always copies file reference)
  - `:CopyLineContext` (copies current line or selection)
  - `:CopyGitHubFile` (copies GitHub file link with current commit)
  - `:CopyGitHubPermalink` (copies GitHub permalink with lines and current commit)

The plugin writes to the system clipboard (`+`) and the unnamed register (`"`). A small notification displays what was copied.

## Options

- `disable_default_keymap` (boolean, default `false`): if `true`, no mappings are created. Define your own, e.g.:

```lua
vim.keymap.set("n", "<leader>cf", "<cmd>CopyFileContext<cr>", { desc = "Copy file context" })
vim.keymap.set({ "n", "v" }, "<leader>cs", "<cmd>CopyLineContext<cr>", { desc = "Copy selection/line context" })
vim.keymap.set({ "n", "v" }, "<leader>cgy", "<cmd>CopyGitHubPermalink<cr>", { desc = "Copy GitHub permalink" })
vim.keymap.set("n", "<leader>cgY", "<cmd>CopyGitHubFile<cr>", { desc = "Copy GitHub file link" })
```

## License

MIT — see [LICENSE](./LICENSE).
