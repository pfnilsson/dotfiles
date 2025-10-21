local M = {}

local function detect_python(root)
	local candidates = {
		vim.fs.joinpath(root, ".venv", "bin", "python"),
		vim.fs.joinpath(root, "venv", "bin", "python"),
	}
	for _, p in ipairs(candidates) do
		local st = vim.loop.fs_stat(p)
		if st and st.type == "file" then
			return p
		end
	end
	if vim.fn.exepath("python3") ~= "" then
		return vim.fn.exepath("python3")
	end
	return vim.fn.exepath("python")
end

function M.setup(capabilities)
	vim.lsp.config("basedpyright", {
		capabilities = capabilities,

		before_init = function(params, config)
			local root = params.rootUri and vim.uri_to_fname(params.rootUri) or vim.loop.cwd()
			config.settings = config.settings or {}
			config.settings.python = config.settings.python or {}
			if not config.settings.python.pythonPath then
				config.settings.python.pythonPath = detect_python(root)
			end
		end,

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
