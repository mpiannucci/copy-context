local M = {}

function M.setup(opts)
    opts = opts or {}
    
    -- Set up the copy context command
    vim.api.nvim_create_user_command('CopyContext', function()
        M.copy_context()
    end, {})
    
    -- Set up default keybindings if not disabled
    if not opts.disable_default_keymap then
        vim.keymap.set('n', '<leader>cf', function()
            M.copy_file()
        end, { desc = 'Copy file context' })
        vim.keymap.set({ 'n', 'v' }, '<leader>cs', function()
            M.copy_visual_or_line()
        end, { desc = 'Copy visual selection context' })
    end
end

-- Build the base reference for the current buffer's path
local function build_base_ref()
    local current_file = vim.fn.expand('%')
    local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')
    local base_path
    if vim.v.shell_error == 0 and git_root ~= '' then
        base_path = git_root
    else
        base_path = vim.fn.getcwd()
    end

    local relative_path = vim.fn.fnamemodify(current_file, ':p')
    if string.sub(relative_path, 1, #base_path) == base_path then
        relative_path = string.sub(relative_path, #base_path + 2)
    else
        relative_path = vim.fn.fnamemodify(current_file, ':.')
    end

    return '@' .. relative_path
end

-- Write to clipboards and notify
local function finish_copy(ref)
    vim.fn.setreg('+', ref)
    vim.fn.setreg('"', ref)
    vim.notify('Copied: ' .. ref, vim.log.levels.INFO)
end

function M.copy_file()
    local base = build_base_ref()
    finish_copy(base)
end

function M.copy_visual_or_line()
    local base = build_base_ref()
    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' or mode == '\22' -- visual modes
        or mode == 's' or mode == 'S' or mode == '\19' -- select modes
    then
        local vpos = vim.fn.getpos('v')
        local cpos = vim.fn.getpos('.')
        local first = math.min(vpos[2], cpos[2])
        local last = math.max(vpos[2], cpos[2])
        if first == last then
            finish_copy(base .. '#L' .. first)
        else
            finish_copy(base .. '#L' .. first .. '-' .. last)
        end
    else
        local line = vim.fn.line('.')
        finish_copy(base .. '#L' .. line)
    end
end

-- Backwards-compatible smart command: selection if present, else file
function M.copy_context()
    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' or mode == '\22' or mode == 's' or mode == 'S' or mode == '\19' then
        return M.copy_visual_or_line()
    else
        return M.copy_file()
    end
end

return M