local M = {}
function M.setup(capabilities)
	vim.lsp.config("lua_ls", {
		capabilities = capabilities,
		settings = {
			Lua = {
				diagnostics = { globals = { "vim", "require" } },
				completion = { callSnippet = "Replace" },
				format = { enable = false },
			},
		},
	})
	vim.lsp.enable("lua_ls")
end

return M
