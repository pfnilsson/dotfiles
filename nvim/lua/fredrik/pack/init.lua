vim.api.nvim_create_user_command("PackUpdate", function()
	vim.pack.update()
end, {})

-- Build hooks MUST be defined before vim.pack.add()
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
			if not ev.data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end
	end,
})

vim.pack.add({
	-- Colorscheme
	"https://github.com/catppuccin/nvim",

	-- Core UI
	"https://github.com/folke/snacks.nvim",
	"https://github.com/folke/which-key.nvim",
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/echasnovski/mini.icons",

	-- Completion
	{ src = "https://github.com/saghen/blink.cmp", version = vim.version.range("*") },
	"https://github.com/rafamadriz/friendly-snippets",

	-- Treesitter
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/nvim-treesitter/nvim-treesitter-context",
	"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
	"https://github.com/HiPhish/rainbow-delimiters.nvim",
	"https://github.com/JoosepAlviste/nvim-ts-context-commentstring",

	-- LSP
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/folke/lazydev.nvim",
	"https://github.com/antosha417/nvim-lsp-file-operations",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",

	-- Editing
	"https://github.com/kylechui/nvim-surround",
	"https://github.com/numToStr/Comment.nvim",
	"https://github.com/windwp/nvim-autopairs",
	"https://github.com/echasnovski/mini.ai",

	-- Navigation
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },

	-- Formatting & linting
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/nvimtools/none-ls.nvim",

	-- Git
	"https://github.com/lewis6991/gitsigns.nvim",

	-- Markdown
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",

	-- AI
	"https://github.com/folke/sidekick.nvim",

	-- DAP
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/leoluz/nvim-dap-go",
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/theHamsta/nvim-dap-virtual-text",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/VanyaDNDZ/nvim-dap-bazel-go",

	-- Utilities
	"https://github.com/nvim-lua/plenary.nvim",
})

-- Configure plugins (order matters: dependencies first)
require("fredrik.pack.colorscheme")
require("fredrik.pack.snacks")
require("fredrik.pack.treesitter")
require("fredrik.pack.blink")
require("fredrik.pack.lsp")
require("fredrik.pack.which-key")
require("fredrik.pack.lualine")
require("fredrik.pack.gitsigns")
require("fredrik.pack.comment")
require("fredrik.pack.conform")
require("fredrik.pack.none-ls")
require("fredrik.pack.editing")
require("fredrik.pack.harpoon")
require("fredrik.pack.markdown")
require("fredrik.pack.rainbow")
require("fredrik.pack.sidekick")

-- Defer heavy, rarely-used plugins
vim.schedule(function()
	require("fredrik.pack.dap")
end)
