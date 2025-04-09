local function strip_trailing_slash(path)
    return path:gsub("/$", "")
end

return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        { "antosha417/nvim-lsp-file-operations", config = true },
        { "folke/neodev.nvim",                   opts = {} },
    },
    config = function()
        -- Import required plugins
        local lspconfig = require("lspconfig")
        local mason_lspconfig = require("mason-lspconfig")
        local blink_cmp = require("blink.cmp")
        local secrets = require("fredrik.load_secrets")

        -- Inline Diagnostic Configuration
        vim.diagnostic.config({
            virtual_text = { prefix = '●' },
            signs = {
                active = {
                    { name = "DiagnosticSignError", text = "✗" },
                    { name = "DiagnosticSignWarn", text = "!" },
                    { name = "DiagnosticSignHint", text = "➤" },
                    { name = "DiagnosticSignInfo", text = "I" },
                },
            },
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = { border = "rounded", source = "always" },
        })

        -- Create an autocommand for LSP attachment to set keybindings
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                -- Buffer local mappings.
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,
                    { buffer = ev.buf, silent = true, desc = "Smart rename" })
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
        local capabilities = blink_cmp.get_lsp_capabilities()

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
            ["gopls"] = function()
                lspconfig["gopls"].setup({
                    capabilities = capabilities,
                    root_dir = function(fname)
                        local util = require("lspconfig.util")

                        -- If we find a WORKSPACE in the ancestry, prefer that (typical Bazel approach).
                        local root = util.root_pattern("WORKSPACE", "WORKSPACE.bzlmod")(fname)

                        if root then
                            return root
                        end

                        if fname:find("^" .. secrets.repo_path) or fname:find(secrets.cache_path) then
                            return strip_trailing_slash(secrets.repo_path)
                        end

                        -- Fallback: if not recognized as a Bazel path, use normal approach
                        return util.root_pattern("go.mod", ".git")(fname) or vim.fn.getcwd()
                    end,
                    on_new_config = function(new_config, root_dir)
                        if strip_trailing_slash(root_dir) == strip_trailing_slash(secrets.repo_path) then
                            new_config.cmd_env = vim.tbl_extend("force", new_config.cmd_env or {}, {
                                GOPACKAGESDRIVER = secrets.repo_path .. "scripts/gopackagesdriver.sh",
                                GOROOT = secrets.repo_path .. secrets.go_root
                            })
                        end
                    end,
                    settings = {
                        gopls = {
                            directoryFilters = {
                                "-bazel-bin",
                                "-bazel-out",
                                "-bazel-testlogs",
                                secrets.bazel_dir_filter,
                            },
                            analyses         = {
                                unusedparams = true,
                                unusedwrite = true,
                            },
                            staticcheck      = true,

                            -- Enable gofumpt for formatting
                            gofumpt          = true,

                            -- Local import organization
                            ["local"]        = secrets.local_import_path,

                            -- UI-related settings
                            usePlaceholders  = true, -- Use placeholders in completions
                            semanticTokens   = true, -- Enable semantic tokens
                            codelenses       = {
                                gc_details = false,
                                regenerate_cgo = false,
                                generate = false,
                                test = false,
                                tidy = false,
                                upgrade_dependency = false,
                                vendor = false,
                            },
                        },
                    },
                })
            end,
        })
    end,
}
