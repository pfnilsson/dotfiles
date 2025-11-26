return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-context",
		config = function()
			require("treesitter-context").setup({ enable = false })

			vim.keymap.set("n", "<leader>t", function()
				require("treesitter-context").toggle()
			end, { desc = "Toggle Treesitter Context" })

			vim.keymap.set("n", "<leader>T", function()
				require("treesitter-context").go_to_context(vim.v.count1)
			end, { silent = true })
		end,
	},
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"lua",
				"rust",
				"python",
				"go",
				"markdown",
				"json",
				"vim",
				"javascript",
				"typescript",
				"cpp",
				"c",
				"terraform",
				"zig",
			},
			highlight = { enable = true, additional_vim_regex_highlighting = false },
			indent = { enable = true },
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-h>",
					node_incremental = "<C-h>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			modules = {},
			sync_install = false,
			ignore_install = {},
			auto_install = true,
		})
	end,
}
