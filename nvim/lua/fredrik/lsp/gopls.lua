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

local function load_repo_gopls_config()
	if not has_repo_gopls then
		return {}
	end

	local path = project_nvim .. "/lsp/gopls.lua"
	local ok, cfg = pcall(dofile, path)

	if not ok then
		vim.notify("Failed to load repo gopls config: " .. tostring(cfg), vim.log.levels.WARN)
		return {}
	end

	if type(cfg) ~= "table" then
		vim.notify("Repo gopls config did not return a table: " .. path, vim.log.levels.WARN)
		return {}
	end

	return cfg
end

local function gopackagedriver_root()
	return util.root_pattern("scripts/gopackagesdriver.sh")(vim.fn.getcwd())
end

local gopls_defaults = {
	analyses = { unusedparams = true, unusedwrite = true },
	staticcheck = true,
	gofumpt = false, -- use standalone gofumpt (via mason) for newer version
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
		local repo_cfg = load_repo_gopls_config()

		local repo_settings = vim.deepcopy(repo_cfg.settings or {})
		if repo_settings.gopls ~= nil and type(repo_settings.gopls) ~= "table" then
			vim.notify(
				"Ignoring invalid repo gopls settings; expected table, got " .. type(repo_settings.gopls),
				vim.log.levels.WARN
			)
			repo_settings.gopls = {}
		end

		local final_cfg = vim.tbl_deep_extend("force", repo_cfg, {
			capabilities = capabilities,
			single_file_support = false,
			cmd_env = vim.tbl_deep_extend("force", repo_cfg.cmd_env or {}, {
				GOPACKAGESDRIVER_PEDREGAL_FORK = "true",
				GOPACKAGESDRIVER_PER_WORKTREE_SERVER = "true",
				GOPACKAGESDRIVER_BAZEL_REMOTE_CACHE = "true",
				GOPACKAGESDRIVER_WORKSPACE_SCOPE_FILE = vim.env.HOME .. "/.config/monorepo/scope",
			}),
			settings = vim.tbl_deep_extend("force", {
				gopls = gopls_defaults,
			}, repo_settings),
			root_dir = function(bufnr, on_dir)
				on_dir(
					gopackagedriver_root()
						or util.root_pattern("go.work", "go.mod", ".git")(vim.api.nvim_buf_get_name(bufnr))
				)
			end,
		})

		vim.lsp.config("gopls", final_cfg)
	else
		vim.lsp.config("gopls", {
			capabilities = capabilities,
			settings = {
				gopls = gopls_defaults,
			},
		})
	end

	vim.lsp.enable("gopls")
end

return M
