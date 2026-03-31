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
