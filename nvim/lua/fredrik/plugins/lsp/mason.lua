return {
    "mason-org/mason.nvim",
    dependencies = {
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
        -- import mason
        local mason = require("mason")

        -- import mason-lspconfig
        local mason_lspconfig = require("mason-lspconfig")

        local mason_tool_installer = require("mason-tool-installer")

        -- enable mason and configure icons
        mason.setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

        ---@diagnostic disable-next-line: missing-fields
        mason_lspconfig.setup({
            -- list of servers for mason to install
            ensure_installed = {
                "html",
                "lua_ls",
                "basedpyright",
                "gopls",
                "rust_analyzer",
                "ruff",
                "jsonls",
                "sqls",
                "terraformls",
            },
        })

        mason_tool_installer.setup({
            ensure_installed = {
                "prettier",
                "stylua",
                "pylint",
                "eslint_d",
                "delve",
                "copilot-language-server"
            },
        })
    end,
}
