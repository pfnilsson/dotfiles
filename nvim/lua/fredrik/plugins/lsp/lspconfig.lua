local function get_black_line_length()
    local filepath = "pyproject.toml"
    local file = io.open(filepath, "r")
    if not file then
        return nil -- pyproject.toml not found
    end

    local found_black_section = false
    for line in file:lines() do
        if line == "[tool.black]" then
            found_black_section = true
        elseif found_black_section then
            -- Stop if we encounter a new section
            if string.match(line, "^%[.-%]") then
                break
            end

            -- Check for "line-length" and extract the value
            if string.match(line, "^%s*line%-length%s*=") then
                file:close()
                return tonumber(string.match(line, "= *(%d+)$"))
            end
        end
    end

    file:close()
    return nil -- "line-length" not found in [tool.black]
end

return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "antosha417/nvim-lsp-file-operations", config = true },
        { "folke/neodev.nvim",                   opts = {} },
    },
    config = function()
        -- Import required plugins
        local lspconfig = require("lspconfig")
        local mason_lspconfig = require("mason-lspconfig")
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        -- Inline Diagnostic Configuration
        vim.diagnostic.config({
            virtual_text = {
                prefix = '●', -- Could be '■', '▎', etc.
            },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
                border = "rounded",
                source = "always", -- Show the source (ruff, flake8) in floating windows
            },
        })

        -- Define signs for different severities
        local signs = { Error = "✗", Warn = "!", Hint = "➤", Info = "I" }
        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
        end

        -- Create an autocommand for LSP attachment to set keybindings
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                -- Buffer local mappings.
                local opts = { buffer = ev.buf, silent = true }

                -- Set keybinds with descriptions
                opts.desc = "Show LSP references"
                vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)

                opts.desc = "Go to declaration"
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

                opts.desc = "Show LSP definitions"
                vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

                opts.desc = "Show LSP implementations"
                vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

                opts.desc = "Show LSP type definitions"
                vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

                opts.desc = "Smart rename"
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            end,
        })

        -- Disable hover for Ruff in favor of Pyright
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if client == nil then
                    return
                end
                if client.name == "ruff" then
                    -- Disable hover in favor of Pyright
                    client.server_capabilities.hoverProvider = false
                end
            end,
            desc = "LSP: Disable hover capability from Ruff",
        })

        -- Enhance capabilities for autocompletion
        local capabilities = cmp_nvim_lsp.default_capabilities()

        -- Setup Mason LSP configurations with custom handlers
        mason_lspconfig.setup_handlers({
            -- Default handler for all servers
            function(server_name)
                lspconfig[server_name].setup({
                    capabilities = capabilities,
                })
            end,

            -- Handler for lua_ls with specific settings
            ["lua_ls"] = function()
                lspconfig["lua_ls"].setup({
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            diagnostics = {
                                globals = { "vim" },
                            },
                            completion = {
                                callSnippet = "Replace",
                            },
                        },
                    },
                })
            end,


            ["ruff"] = function()
                local blackLineLen = get_black_line_length()
                local settings = { fixAll = true }

                if blackLineLen ~= nil then
                    settings.lineLength = blackLineLen
                end
                lspconfig["ruff"].setup({
                    capabilities = capabilities,
                    init_options = { settings = settings },
                })
            end,

            -- Handler for basedpyright with Ruff integration
            ["basedpyright"] = function()
                lspconfig["basedpyright"].setup({
                    capabilities = capabilities,
                    settings = {
                        basedpyright = {
                            disableOrganizeImports = true,
                            analysis = {
                                typeCheckingMode = "standard",
                                autoSearchPaths = true,
                                useLibraryCodeForTypes = true,
                                diagnosticsMode = "openFilesOnly",
                                autoImportCompletions = true,
                                diagnosticSeverityOverrides = {
                                    autoSearchPaths = true,
                                    enableTypeIgnoreComments = false,
                                    reportPossiblyUnboundVariable = false,
                                }
                            }
                        },
                    }
                })
            end,
        })
    end,
}
