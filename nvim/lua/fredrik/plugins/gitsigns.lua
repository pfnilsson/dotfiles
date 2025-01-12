return {
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("gitsigns").setup {
            signs = {
                add          = { text = "+" },
                change       = { text = "~" },
                delete       = { text = "_" },
                topdelete    = { text = "‾" },
                changedelete = { text = "~" },
            },
            current_line_blame = true, -- Inline blame annotations
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns

                local function map(mode, l, r, opts)
                    opts = opts or {}
                    opts.buffer = bufnr
                    vim.keymap.set(mode, l, r, opts)
                end

                -- Navigation
                map('n', 'åc', function()
                    if vim.wo.diff then return 'åc' end
                    vim.schedule(function() gs.next_hunk() end)
                    return '<Ignore>'
                end, {expr=true})

                map('n', 'Åc', function()
                    if vim.wo.diff then return 'Åc' end
                    vim.schedule(function() gs.prev_hunk() end)
                    return '<Ignore>'
                end, {expr=true})

                -- Actions
                map('n', '<leader>gr', gs.reset_hunk)
                map('n', '<leader>gR', gs.reset_buffer)
                map('n', '<leader>gp', gs.preview_hunk)
                map('n', '<leader>gb', function() gs.blame_line { full = true } end)
                map('n', '<leader>gb', gs.toggle_current_line_blame)
                map('n', '<leader>gd', gs.diffthis)
                map('n', '<leader>gD', function() gs.diffthis("~") end)
                map('n', '<leader>gd', gs.toggle_deleted)
            end
        }
    end
}
