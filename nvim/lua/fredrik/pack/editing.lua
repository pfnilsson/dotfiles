-- Surround
require("nvim-surround").setup()

-- Autopairs
local npairs = require("nvim-autopairs")
npairs.setup({
	check_ts = true,
	disable_filetype = { "vim" },
	map_bs = true,
	map_cr = true,
	disable_in_macro = true,
	disable_in_visualblock = true,
	ts_config = {
		lua = { "string", "source" },
		javascript = { "template_string" },
		python = { "string", "comment" },
	},
})

local Rule = require("nvim-autopairs.rule")
npairs.add_rules({
	Rule("<", ">", "html"),
})

-- Mini.ai text objects
local miniai = require("mini.ai")
miniai.setup({
	n_lines = 300,
	custom_textobjects = {
		f = miniai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
		g = function()
			local from = { line = 1, col = 1 }
			local to = {
				line = vim.fn.line("$"),
				col = math.max(vim.fn.getline("$"):len(), 1),
			}
			return { from = from, to = to }
		end,
	},
	silent = true,
	search_method = "cover_or_next",
	mappings = {
		around_next = "an",
		inside_next = "in",
		around_last = "al",
		inside_last = "il",
	},
})
