-- Lazydev (enhanced Lua LSP)
require("lazydev").setup({
	library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
})

-- LSP file operations
require("lsp-file-operations").setup()

-- Mason
local registry = require("fredrik.lsp.registry")

require("mason").setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

---@diagnostic disable-next-line: missing-fields
require("mason-lspconfig").setup({ ensure_installed = registry.servers, automatic_enable = false })
require("mason-tool-installer").setup({ ensure_installed = registry.tools })

-- LSP config
if vim.fn.has("linux") == 1 then
	require("fredrik.lsp.external_watch").setup({
		debounce_ms = 200,
		ignored_dirs = {
			["dist"] = true,
			["build"] = true,
			[".direnv"] = true,
		},
	})
end

local S = require("fredrik.lsp.shared").init()
local custom, defaults = registry.partition()

local grp = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
	group = grp,
	callback = function(ev)
		vim.keymap.set(
			"n",
			"<leader>rn",
			vim.lsp.buf.rename,
			{ buffer = ev.buf, silent = true, desc = "Smart rename" }
		)
	end,
})

for _, mod in pairs(custom) do
	require(mod).setup(S.capabilities)
end

for _, name in ipairs(defaults) do
	vim.lsp.config(name, { capabilities = S.capabilities })
	vim.lsp.enable(name)
end
