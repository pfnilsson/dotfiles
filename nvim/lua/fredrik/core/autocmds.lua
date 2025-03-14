-- Auto Commands
-----------------------------------------------------------

-- Create an autocommand that triggers on the TextYankPost event
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
    callback = function()
        vim.highlight.on_yank {
            -- Highlight group to use (you can choose or define your own)
            higroup = 'IncSearch',
            -- Time in milliseconds for the highlight to last
            timeout = 200,
        }
    end,
})

-- save files when leaving
vim.api.nvim_create_autocmd("BufLeave", {
    pattern = "*",
    callback = function()
        vim.cmd("silent! write")
    end,
})

-- check for changes on disk when focusing Neovim or entering a buffer
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
    pattern = "*",
    command = "checktime"
})
