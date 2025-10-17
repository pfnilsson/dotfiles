local M = {}
function M.setup(capabilities)
	vim.lsp.config("ruff", {
		capabilities = capabilities,
		on_init = function(client)
			client.server_capabilities.hoverProvider = false
		end,
	})
	vim.lsp.enable("ruff")
end

return M
