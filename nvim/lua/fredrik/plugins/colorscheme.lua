return {
	"catppuccin/nvim",
	name = "catppuccin",
	lazy = false,
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			flavour = "mocha",
			transparent_background = false,
			term_colors = true,
			integrations = {
				cmp = true,
				gitsigns = true,
				nvimtree = true,
				treesitter = true,
				flash = true,
			},
			highlight_overrides = {
				all = function(colors)
					return {
						FlashMatch = { bg = colors.blue, fg = colors.base, bold = true, nocombine = true },
						FlashCurrent = { bg = colors.peach, fg = colors.base, bold = true, nocombine = true },
						FlashLabel = { bg = colors.red, fg = colors.base, bold = true, nocombine = true },
					}
				end,
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
