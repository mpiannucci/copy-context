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
    
    local context_ref = '@' .. relative_path
    
    -- Check if we're in visual mode to get line selection
    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' or mode == '\22' then -- \22 is visual block mode
        local start_line = vim.fn.line("'<")
        local end_line = vim.fn.line("'>")
        
        if start_line == end_line then
            context_ref = context_ref .. '#L' .. start_line
        else
            context_ref = context_ref .. '#L' .. start_line .. '-' .. end_line
        end
    end
    
    -- Copy to clipboard
    vim.fn.setreg('+', context_ref)
    vim.fn.setreg('"', context_ref)
    
    -- Show notification
    vim.notify('Copied: ' .. context_ref, vim.log.levels.INFO)
end

return M