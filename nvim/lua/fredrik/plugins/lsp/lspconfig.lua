return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = {
				library = {
					{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				},
			},
		},
		{ "folke/snacks.nvim" },
	},
	config = function()
		local ok_blink, blink_cmp = pcall(require, "blink.cmp")
		local capabilities = (ok_blink and blink_cmp.get_lsp_capabilities())
			or vim.lsp.protocol.make_client_capabilities()
		if
			capabilities
			and capabilities.textDocument
			and capabilities.textDocument.completion
			and capabilities.textDocument.completion.completionItem
		then
			capabilities.textDocument.completion.completionItem.snippetSupport = false
		end

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
			callback = function(ev)
				vim.keymap.set(
					"n",
					"<leader>rn",
					vim.lsp.buf.rename,
					{ buffer = ev.buf, silent = true, desc = "Smart rename" }
				)
			end,
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client and client.name == "ruff" then
					client.server_capabilities.hoverProvider = false
				end
			end,
			desc = "LSP: Disable hover capability from Ruff",
		})

		local function find_pattern_dir(pattern)
			local current = vim.fn.getcwd()
			while current ~= "/" do
				local p = current .. "/" .. pattern
				if vim.fn.isdirectory(p) == 1 then
					return p
				end
				current = vim.fn.fnamemodify(current, ":h")
			end
			return nil
		end

		local project_nvim = find_pattern_dir(".nvim")
		if project_nvim then
			vim.opt.runtimepath:append(project_nvim)
		end

		local secrets_ok, secrets = pcall(require, "fredrik.load_secrets")
		local local_import_path = secrets_ok and secrets.local_import_path or nil

		local has_repo_gopls = project_nvim and (vim.fn.filereadable(project_nvim .. "/lsp/gopls.lua") == 1)

		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					completion = { callSnippet = "Replace" },
				},
			},
		})
		vim.lsp.enable("lua_ls")

		vim.lsp.config("basedpyright", {
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
						},
					},
				},
			},
		})
		vim.lsp.enable("basedpyright")

		if has_repo_gopls then
			vim.lsp.config("gopls", { capabilities = capabilities })
		else
			local gopls_settings = {
				analyses = { unusedparams = true, unusedwrite = true },
				staticcheck = true,
				gofumpt = true,
				usePlaceholders = true,
				semanticTokens = true,
				codelenses = {
					gc_details = false,
					regenerate_cgo = false,
					generate = false,
					test = false,
					tidy = false,
					upgrade_dependency = false,
					vendor = false,
				},
			}
			if local_import_path then
				gopls_settings["local"] = local_import_path
			end

			vim.lsp.config("gopls", {
				capabilities = capabilities,
				settings = { gopls = gopls_settings },
			})
		end
		vim.lsp.enable("gopls")

		vim.api.nvim_create_user_command("GoplsRestart", function()
			vim.cmd("LspRestart gopls")
		end, { desc = "Restart gopls" })
	end,
}
