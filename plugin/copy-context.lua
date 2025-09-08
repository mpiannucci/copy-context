-- Auto-setup for non-LazyVim users
if not vim.g.loaded_copy_context then
    vim.g.loaded_copy_context = 1
    
    -- Only auto-setup if LazyVim is not detected
    if not package.loaded['lazy'] then
        require('copy-context').setup()
    end
end