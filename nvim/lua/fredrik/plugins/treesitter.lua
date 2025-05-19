return {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
        "nvim-treesitter/nvim-treesitter-context",
        config = function() require("treesitter-context").setup({ enable = false }) end
    },
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "lua",
                "rust",
                "python",
                "go",
                "markdown",
                "json",
                "vim",
                "javascript",
                "typescript",
                "cpp",
                "c",
                "terraform"
            },
            highlight = { enable = true, additional_vim_regex_highlighting = false },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-h>",
                    node_incremental = "<C-h>",
                    scope_incremental = false,
                    node_decremental = "<C-H>",
                },
            },
            modules = {},
            sync_install = false,
            ignore_install = {},
            auto_install = true,
        })
    end
}
