local M = {}
function M.setup(capabilities)
	vim.lsp.config("templ", {
		capabilities = capabilities,
		-- The project's templ, pinned as a tool in its go.mod, run from the
		-- project root, so the server generates what the project's build does.
		cmd = function(dispatchers, config)
			return vim.lsp.rpc.start({ "go", "tool", "templ", "lsp" }, dispatchers, { cwd = config.root_dir })
		end,
	})
	vim.lsp.enable("templ")
end

return M
