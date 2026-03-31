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
