return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
		},
		{ "folke/snacks.nvim" },
	},
	config = function()
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
		local registry = require("fredrik.lsp.registry")
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
	end,
}
