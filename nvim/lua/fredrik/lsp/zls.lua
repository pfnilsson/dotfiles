local M = {}
function M.setup(capabilities)
	vim.lsp.config("zls", {
		capabilities = capabilities,
		settings = {
			zls = {
				enable_ast_check_diagnostics = true,
				warn_style = true,
				enable_semantic_tokens = true,
				enable_import_embedfile_argument_completions = true,
				operator_completions = true,
				include_at_in_builtins = true,
			},
		},
	})
	vim.lsp.enable("zls")
end

return M
