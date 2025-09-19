We are making a neovim plugin called `copy-context` that copies file and line
references in multiple formats for use with AI agents and sharing code.

## Core Functionality

### AI Agent Format
Copy file references in `@file` format for AI agents:
- File: `@src/main.py`
- Single line: `@src/main.py#L5`
- Line range: `@src/main.py#L5-10`

### GitHub Permalinks
Copy GitHub URLs that link directly to code:
- File: `https://github.com/user/repo/blob/v1.2.3/src/main.py`
- With lines: `https://github.com/user/repo/blob/v1.2.3/src/main.py#L5-L10`

## Smart Reference Selection

The plugin intelligently chooses the best commit reference:
1. **Git tags** (v1.2.3) - for prettier, stable URLs
2. **Upstream merge-base** - for branch collaboration
3. **Current HEAD** - fallback for local work

Paths resolve relative to git root when available, otherwise relative to cwd.

## Commands & Keybindings

- `<leader>cf` / `:CopyFileContext` - Copy AI agent file reference
- `<leader>cs` / `:CopyLineContext` - Copy AI agent line reference
- `<leader>cgY` / `:CopyGitHubFile` - Copy GitHub file link
- `<leader>cgy` / `:CopyGitHubPermalink` - Copy GitHub permalink with lines

The plugin is loadable via LazyVim from the `mpiannucci/copy-context` repository.
