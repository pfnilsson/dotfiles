return {
	"HiPhish/rainbow-delimiters.nvim",
	submodules = false,
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		vim.g.rainbow_delimiters = {
			strategy = {
				[""] = require("rainbow-delimiters").strategy["global"],
				vim = require("rainbow-delimiters").strategy["local"],
			},
			query = {
				[""] = "rainbow-delimiters",
			},
			priority = {
				[""] = 110,
				lua = 210,
			},
			highlight = {
				"RainbowDelimiterYellow",
				"RainbowDelimiterRed",
				"RainbowDelimiterBlue",
				"RainbowDelimiterOrange",
				"RainbowDelimiterGreen",
				"RainbowDelimiterViolet",
				"RainbowDelimiterCyan",
			},
		}

		local colors = {
			RainbowDelimiterRed = "#E06C75",
			RainbowDelimiterYellow = "#E5C07B",
			RainbowDelimiterBlue = "#61AFEF",
			RainbowDelimiterOrange = "#D19A66",
			RainbowDelimiterGreen = "#98C379",
			RainbowDelimiterViolet = "#C678DD",
			RainbowDelimiterCyan = "#56B6C2",
		}

		for group, color in pairs(colors) do
			vim.api.nvim_set_hl(0, group, { fg = color })
		end
	end,
}
