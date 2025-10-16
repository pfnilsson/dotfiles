local M = {}
function M.setup(capabilities)
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
end

return M
