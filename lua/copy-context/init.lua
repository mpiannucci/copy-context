local M = {}

function M.setup(opts)
    opts = opts or {}

    -- Set up user commands
    vim.api.nvim_create_user_command('CopyContext', function()
        M.copy_context()
    end, {})

    vim.api.nvim_create_user_command('CopyFileContext', function()
        M.copy_file()
    end, {})

    vim.api.nvim_create_user_command('CopyLineContext', function()
        M.copy_visual_or_line()
    end, { range = true })

    vim.api.nvim_create_user_command('CopyGitHubPermalink', function()
        M.copy_github_permalink()
    end, { range = true })

    vim.api.nvim_create_user_command('CopyGitHubFile', function()
        M.copy_github_file()
    end, {})

    -- Set up default keybindings if not disabled
    if not opts.disable_default_keymap then
        vim.keymap.set('n', '<leader>cf', function()
            M.copy_file()
        end, { desc = 'Copy file context' })
        vim.keymap.set({ 'n', 'v' }, '<leader>cs', function()
            M.copy_visual_or_line()
        end, { desc = 'Copy visual selection context' })
        vim.keymap.set({ 'n', 'v' }, '<leader>cgy', function()
            M.copy_github_permalink()
        end, { desc = 'Copy GitHub permalink' })
        vim.keymap.set('n', '<leader>cgY', function()
            M.copy_github_file()
        end, { desc = 'Copy GitHub file link' })
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

-- Get GitHub remote URL and parse repo info
local function get_github_repo_info()
    -- Try upstream first, then origin
    local remotes = {'upstream', 'origin'}

    for _, remote in ipairs(remotes) do
        local remote_url = vim.fn.system('git remote get-url ' .. remote .. ' 2>/dev/null'):gsub('\n', '')
        if vim.v.shell_error == 0 and remote_url ~= '' then
            -- Parse GitHub URL (both SSH and HTTPS formats)
            local user, repo

            -- SSH format: git@github.com:user/repo.git
            user, repo = remote_url:match('git@github%.com:([^/]+)/([^%.]+)%.git')

            -- HTTPS format: https://github.com/user/repo.git
            if not user then
                user, repo = remote_url:match('https://github%.com/([^/]+)/([^%.]+)%.git')
            end

            -- HTTPS format without .git: https://github.com/user/repo
            if not user then
                user, repo = remote_url:match('https://github%.com/([^/]+)/([^/]+)/?$')
            end

            if user and repo then
                return user, repo
            end
        end
    end

    return nil, nil
end

-- Build GitHub permalink
local function build_github_permalink()
    local current_file = vim.fn.expand('%')
    local git_root = vim.fn.system('git rev-parse --show-toplevel 2>/dev/null'):gsub('\n', '')

    if vim.v.shell_error ~= 0 or git_root == '' then
        return nil, "Not in a git repository"
    end

    local user, repo = get_github_repo_info()
    if not user or not repo then
        return nil, "Could not find GitHub remote (upstream or origin)"
    end

    -- Get commit hash - try upstream branch first, then HEAD
    local commit_hash

    -- Try to get the upstream commit if we're on a tracking branch
    local upstream_branch = vim.fn.system('git rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null'):gsub('\n', '')
    if vim.v.shell_error == 0 and upstream_branch ~= '' then
        -- We have an upstream, use the merge-base (common ancestor) or upstream HEAD
        local merge_base = vim.fn.system('git merge-base HEAD ' .. upstream_branch .. ' 2>/dev/null'):gsub('\n', '')
        if vim.v.shell_error == 0 and merge_base ~= '' then
            -- Use merge-base if it exists (this is the common commit between local and upstream)
            commit_hash = merge_base
        else
            -- Fallback to upstream HEAD
            commit_hash = vim.fn.system('git rev-parse ' .. upstream_branch .. ' 2>/dev/null'):gsub('\n', '')
        end
    end

    -- Fallback to current HEAD if upstream logic fails
    if not commit_hash or commit_hash == '' or vim.v.shell_error ~= 0 then
        commit_hash = vim.fn.system('git rev-parse HEAD 2>/dev/null'):gsub('\n', '')
        if vim.v.shell_error ~= 0 or commit_hash == '' then
            return nil, "Could not get current commit hash"
        end
    end

    -- Get relative path from git root
    local relative_path = vim.fn.fnamemodify(current_file, ':p')
    if string.sub(relative_path, 1, #git_root) == git_root then
        relative_path = string.sub(relative_path, #git_root + 2)
    else
        return nil, "File is not within git repository"
    end

    return string.format('https://github.com/%s/%s/blob/%s/%s', user, repo, commit_hash, relative_path), nil
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

function M.copy_github_file()
    vim.notify('Debug: copy_github_file called', vim.log.levels.INFO)
    local permalink, err = build_github_permalink()
    if not permalink then
        vim.notify('GitHub file error: ' .. err, vim.log.levels.ERROR)
        return
    end

    finish_copy(permalink)
end

function M.copy_github_permalink()
    vim.notify('Debug: copy_github_permalink called', vim.log.levels.INFO)
    local permalink, err = build_github_permalink()
    if not permalink then
        vim.notify('GitHub permalink error: ' .. err, vim.log.levels.ERROR)
        return
    end

    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' or mode == '\22' -- visual modes
        or mode == 's' or mode == 'S' or mode == '\19' -- select modes
    then
        local vpos = vim.fn.getpos('v')
        local cpos = vim.fn.getpos('.')
        local first = math.min(vpos[2], cpos[2])
        local last = math.max(vpos[2], cpos[2])
        if first == last then
            finish_copy(permalink .. '#L' .. first)
        else
            finish_copy(permalink .. '#L' .. first .. '-L' .. last)
        end
    else
        local line = vim.fn.line('.')
        finish_copy(permalink .. '#L' .. line)
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