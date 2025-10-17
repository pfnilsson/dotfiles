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
					diagnosticsMode = "workspace",
					autoImportCompletions = true,
					enableTypeIgnoreComments = false,
					diagnosticSeverityOverrides = {
						reportMissingImports = "error",
						reportUnusedImport = "warning",
						reportUnusedVariable = "warning",
						reportPossiblyUnboundVariable = "none",
						reportUnnecessaryTypeIgnoreComment = "warning",
					},
				},
			},
		},
	})
	vim.lsp.enable("basedpyright")
end

return M
