-- highlight yanks
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
    callback = function()
        vim.highlight.on_yank {
            higroup = 'IncSearch',
            timeout = 200,
        }
    end,
})

-- check for changes on disk when focusing Neovim or entering a buffer
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    pattern = "*",
    command = "checktime"
})
