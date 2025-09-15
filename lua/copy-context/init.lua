local M = {}

function M.setup(opts)
    opts = opts or {}
    
    -- Set up the copy context command
    vim.api.nvim_create_user_command('CopyContext', function()
        M.copy_context()
    end, {})
    
    -- Set up default keybinding if not disabled
    if not opts.disable_default_keymap then
        vim.keymap.set({'n', 'v'}, '<leader>cc', function()
            M.copy_context()
        end, { desc = 'Copy context reference' })
    end
end

function M.copy_context()
    local current_file = vim.fn.expand('%')
    
    -- Get relative path from git root or current working directory
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
    
    local base_ref = '@' .. relative_path

    local function finish_copy(suffix)
        local ref = base_ref .. (suffix or '')
        vim.fn.setreg('+', ref)
        vim.fn.setreg('"', ref)
        vim.notify('Copied: ' .. ref, vim.log.levels.INFO)
    end

    -- Detect Visual/Select and read positions without leaving the mode
    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' or mode == '\22' -- visual modes
        or mode == 's' or mode == 'S' or mode == '\19' -- select modes
    then
        local vpos = vim.fn.getpos('v') -- {buf, lnum, col, off}
        local cpos = vim.fn.getpos('.') -- cursor
        local first = math.min(vpos[2], cpos[2])
        local last = math.max(vpos[2], cpos[2])
        if first == last then
            finish_copy('#L' .. first)
        else
            finish_copy('#L' .. first .. '-' .. last)
        end
    else
        finish_copy('')
    end
end

return M