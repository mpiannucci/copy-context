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

-- Execute git command and return output or nil on failure
local function git_cmd(cmd)
    local output = vim.fn.system('git ' .. cmd .. ' 2>/dev/null'):gsub('\n', '')
    if vim.v.shell_error == 0 and output ~= '' then
        return output
    end
    return nil
end

-- Get tag name for a commit if it exists
local function get_tag_for_commit(commit_ref)
    return git_cmd('describe --exact-match --tags ' .. (commit_ref or 'HEAD'))
end

-- Build the base reference for the current buffer's path
local function build_base_ref()
    local current_file = vim.fn.expand('%')
    if current_file == '' then
        return '@[No file]'
    end

    -- Use simple git detection without expensive git commands
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
        local remote_url = git_cmd('remote get-url ' .. remote)
        if remote_url then
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
    if current_file == '' then
        return nil, "No file open"
    end

    local git_root = git_cmd('rev-parse --show-toplevel')
    if not git_root then
        return nil, "Not in a git repository"
    end

    local user, repo = get_github_repo_info()
    if not user or not repo then
        return nil, "Could not find GitHub remote (upstream or origin)"
    end

    -- Get commit reference - prefer tags, then upstream branch, then HEAD
    local commit_ref

    -- First, check if current HEAD is on a tag
    commit_ref = get_tag_for_commit()
    if commit_ref then
        -- Found a tag for current HEAD, use it
    else
        -- Try to get the upstream commit if we're on a tracking branch
        -- Note: this might fail in detached HEAD state (when checked out to a tag)
        local upstream_branch = git_cmd('rev-parse --abbrev-ref --symbolic-full-name @{upstream}')
        if upstream_branch then
            -- We have an upstream, use the merge-base (common ancestor) or upstream HEAD
            local merge_base = git_cmd('merge-base HEAD ' .. upstream_branch)
            if merge_base then
                -- Check if merge-base is on a tag
                commit_ref = get_tag_for_commit(merge_base) or merge_base
            else
                -- Fallback to upstream HEAD
                commit_ref = git_cmd('rev-parse ' .. upstream_branch)
            end
        end

        -- Fallback to current HEAD if upstream logic fails (common in detached HEAD)
        if not commit_ref then
            commit_ref = git_cmd('rev-parse HEAD')
            if not commit_ref then
                return nil, "Could not get current commit hash"
            end
        end
    end

    -- Get relative path from git root
    local relative_path = vim.fn.fnamemodify(current_file, ':p')
    if string.sub(relative_path, 1, #git_root) == git_root then
        relative_path = string.sub(relative_path, #git_root + 2)
    else
        return nil, "File is not within git repository"
    end

    return string.format('https://github.com/%s/%s/blob/%s/%s', user, repo, commit_ref, relative_path), nil
end

-- Check if we're in visual/select mode
local function is_visual_mode()
    local mode = vim.fn.mode()
    return mode == 'v' or mode == 'V' or mode == '\22' -- visual modes
        or mode == 's' or mode == 'S' or mode == '\19' -- select modes
end

-- Get line range for current selection or current line
local function get_line_range()
    if is_visual_mode() then
        local vpos = vim.fn.getpos('v')
        local cpos = vim.fn.getpos('.')
        local first = math.min(vpos[2], cpos[2])
        local last = math.max(vpos[2], cpos[2])
        return first, last
    else
        local line = vim.fn.line('.')
        return line, line
    end
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
    local first, last = get_line_range()

    if first == last then
        finish_copy(base .. '#L' .. first)
    else
        finish_copy(base .. '#L' .. first .. '-' .. last)
    end
end

function M.copy_github_file()
    local permalink, err = build_github_permalink()
    if not permalink then
        vim.notify('GitHub file error: ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
        return
    end

    finish_copy(permalink)
end

function M.copy_github_permalink()
    local permalink, err = build_github_permalink()
    if not permalink then
        vim.notify('GitHub permalink error: ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
        return
    end

    local first, last = get_line_range()

    if first == last then
        finish_copy(permalink .. '#L' .. first)
    else
        finish_copy(permalink .. '#L' .. first .. '-L' .. last)
    end
end

-- Backwards-compatible smart command: selection if present, else file
function M.copy_context()
    if is_visual_mode() then
        return M.copy_visual_or_line()
    else
        return M.copy_file()
    end
end

return M