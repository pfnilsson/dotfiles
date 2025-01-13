return {
    "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
        local nvimtree = require("nvim-tree")

        -- recommended settings from nvim-tree documentation
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        nvimtree.setup({
            view = {
                width = 75,
                relativenumber = true,
            },
            -- change folder arrow icons
            renderer = {
                indent_markers = {
                    enable = true,
                },
                icons = {
                    glyphs = {
                        folder = {
                            arrow_closed = vim.fn.nr2char(0x2192), -- arrow when folder is closed
                            arrow_open = vim.fn.nr2char(0x2193),   -- arrow when folder is open
                        },
                    },
                },
            },
            -- disable window_picker for
            -- explorer to work well with
            -- window splits
            actions = {
                open_file = {
                    quit_on_open = true, -- close the file tree when a file has been selected
                    window_picker = {
                        enable = false,
                    },
                },
            },
            filters = {
                custom = { ".DS_Store" },
            },
            git = {
                ignore = false,
            },
        })


        vim.keymap.set("n", "<leader>tt", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })     -- toggle file explorer
        vim.keymap.set("n", "<leader>tf", "<cmd>NvimTreeFocus<CR>", { desc = "Focus file explorer" })       -- focus file explorer
        vim.keymap.set("n", "<leader>th", "<cmd>NvimTreeFindFileToggle<CR>",
            { desc = "Toggle file explorer on current file" })                                              -- toggle file explorer on current file (here)
        vim.keymap.set("n", "<leader>tc", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }) -- collapse file explorer
        vim.keymap.set("n", "<leader>tr", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })   -- refresh file explorer
    end
}
