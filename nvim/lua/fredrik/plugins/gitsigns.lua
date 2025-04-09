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
            on_attach = function(_)
                local gs = package.loaded.gitsigns

                -- Navigation
                vim.keymap.set('n', 'åc', function()
                    if vim.wo.diff then return 'åc' end
                    vim.schedule(function() gs.next_hunk() end)
                    return '<Ignore>'
                end, { expr = true })

                vim.keymap.set('n', 'Åc', function()
                    if vim.wo.diff then return 'Åc' end
                    vim.schedule(function() gs.prev_hunk() end)
                    return '<Ignore>'
                end, { expr = true })

                -- Actions
                vim.keymap.set('n', '<leader>gr', gs.reset_hunk, { desc = "Reset Hunk" })
                vim.keymap.set('n', '<leader>gR', gs.reset_buffer, { desc = "Reset Buffer" })
                vim.keymap.set('n', '<leader>gp', gs.preview_hunk, { desc = "Preview Hunk" })
                vim.keymap.set('n', '<leader>gS', gs.stage_hunk, { desc = "Stage Hunk" })
                vim.keymap.set('n', '<leader>gD', gs.toggle_deleted, { desc = "Toggle Deleted" })
            end
        }
    end
}
