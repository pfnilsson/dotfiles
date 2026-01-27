local util = require("lspconfig.util")

local function find_pattern_dir(pattern)
	local cur = vim.fn.getcwd()
	while cur ~= "/" do
		local p = cur .. "/" .. pattern
		if vim.fn.isdirectory(p) == 1 then
			return p
		end
		cur = vim.fn.fnamemodify(cur, ":h")
	end
	return nil
end

local project_nvim = find_pattern_dir(".nvim")
if project_nvim then
	vim.opt.runtimepath:append(project_nvim)
end
local has_repo_gopls = project_nvim and (vim.fn.filereadable(project_nvim .. "/lsp/gopls.lua") == 1)

local function gopackagedriver_root()
	return util.root_pattern("scripts/gopackagesdriver.sh")(vim.fn.getcwd())
end

local DRIVER_PACKAGE = "nodes/platform/decisionsystems/..."
local gopls_defaults = {
	analyses = { unusedparams = true, unusedwrite = true },
	staticcheck = true,
	gofumpt = true,
	usePlaceholders = false,
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

local M = {}

function M.setup(capabilities)
	if has_repo_gopls then
		vim.lsp.config("gopls", {
			capabilities = capabilities,
			single_file_support = false,
			cmd_env = { GOPACKAGESDRIVER_PACKAGE = DRIVER_PACKAGE, GOPACKAGESDRIVER_WORKSPACE_SCOPE = "" },
			on_new_config = function(cfg, _)
				cfg.settings = cfg.settings or {}
				cfg.settings.gopls = vim.tbl_deep_extend("keep", cfg.settings.gopls or {}, gopls_defaults)
				cfg.settings.gopls.env = vim.tbl_extend("force", cfg.settings.gopls.env or {}, {
					GOPACKAGESDRIVER_PACKAGE = DRIVER_PACKAGE,
					GOPACKAGESDRIVER_WORKSPACE_SCOPE = "",
				})
			end,
			root_dir = function(bufnr, on_dir)
				on_dir(
					gopackagedriver_root()
						or util.root_pattern("go.work", "go.mod", ".git")(vim.api.nvim_buf_get_name(bufnr))
				)
			end,
		})
	else
		vim.lsp.config("gopls", {
			capabilities = capabilities,
			settings = { gopls = gopls_defaults },
		})
	end
	vim.lsp.enable("gopls")
end

return M
