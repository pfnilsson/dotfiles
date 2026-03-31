require("conform").setup({
	formatters_by_ft = {
		go = { "gofumpt" },
		python = { "isort", "black" },
		sql = { "sleek" },
		lua = { "stylua" },
	},
	format_on_save = {
		timeout_ms = 400,
		lsp_format = "fallback",
	},
})
