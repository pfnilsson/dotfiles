return {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "mocha",
            transparent_background = false,
            term_colors = true,
            integrations = {
                cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
            },
        })
        vim.cmd.colorscheme("catppuccin")
    end,
}
