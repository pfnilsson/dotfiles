return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		formatters_by_ft = {
			python = { "isort", "black" },
			sql = { "sleek" },
			lua = { "stylua" },
		},
		format_on_save = {
			timeout_ms = 400,
			lsp_format = "fallback",
		},
	},
}
