-- Auto Commands
-----------------------------------------------------------

-- Fix and format the buffer before writing if an LSP client is attached
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })

        if vim.tbl_isempty(clients) then
            return
        end

        for _, client in ipairs(clients) do
            if client.supports_method("textDocument/formatting") then
                vim.lsp.buf.format({
                    bufnr = bufnr,
                    async = false,
                    timeout_ms = 2000,
                })
                break
            end
        end
    end,
})

-- Create an autocommand that triggers on the TextYankPost event
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
    callback = function()
        vim.highlight.on_yank {
            -- Highlight group to use (you can choose or define your own)
            higroup = 'IncSearch',
            -- Time in milliseconds for the highlight to last
            timeout = 200,
            -- Optionally, specify whether to include the visual selection
            -- currently not needed, as we're yanking outside visual mode
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
