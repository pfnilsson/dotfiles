local M = {}

local function detect_python(root)
	local candidates = {
		vim.fs.joinpath(root, ".venv", "bin", "python"),
		vim.fs.joinpath(root, "venv", "bin", "python"),
	}
	for _, p in ipairs(candidates) do
		local st = vim.uv.fs_stat(p)
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
	vim.lsp.config("ty", {
		capabilities = capabilities,
		cmd = { "ty", "server" },
		filetypes = { "python" },
		before_init = function(params, config)
			local root = params.rootUri and vim.uri_to_fname(params.rootUri) or vim.uv.cwd()

			config.settings = config.settings or {}
			config.settings.ty = config.settings.ty or {}
			config.settings.ty.configuration = config.settings.ty.configuration or {}

			config.settings.ty.configuration.environment = config.settings.ty.configuration.environment or {}
			if not config.settings.ty.configuration.environment.python then
				config.settings.ty.configuration.environment.python = detect_python(root)
			end
		end,
		root_dir = function(bufnr, on_dir)
			local fname = vim.api.nvim_buf_get_name(bufnr)

			if fname:match("bazel%-") or fname:match("/_bazel_") or fname:match("/private/var/tmp/") then
				return
			end

			local util = require("lspconfig.util")
			local root = util.root_pattern("pyproject.toml", "ty.toml", ".git")(fname)
			if root then
				on_dir(root)
			end
		end,
		settings = {
			ty = {
				diagnosticMode = "workspace",

				completions = {
					autoImport = true,
				},
				configuration = {
					analysis = {
						["respect-type-ignore-comments"] = false,
					},

					rules = {
						["unresolved-import"] = "error",
						["possibly-unresolved-reference"] = "warn",
						["unresolved-reference"] = "warn",
					},
				},
			},
		},
	})

	vim.lsp.enable("ty")
end

return M
