local M = {}
function M.setup(capabilities)
	vim.lsp.config("ruff", {
		capabilities = capabilities,
		init_options = {
			settings = {
				lint = {
					select = { "E", "F", "W", "I", "N", "UP", "B", "A", "C4", "SIM", "RUF" },
				},
			},
		},
		on_init = function(client)
			client.server_capabilities.hoverProvider = false
		end,
	})
	vim.lsp.enable("ruff")
end

return M
