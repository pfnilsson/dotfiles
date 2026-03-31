local ts = require("nvim-treesitter")

ts.install({
	"lua",
	"rust",
	"python",
	"go",
	"markdown",
	"markdown_inline",
	"json",
	"vim",
	"vimdoc",
	"javascript",
	"typescript",
	"cpp",
	"c",
	"terraform",
	"zig",
})

vim.api.nvim_create_autocmd("FileType", {
	callback = function(event)
		pcall(vim.treesitter.start, event.buf)
		vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

-- Treesitter context (disabled by default, toggle with <leader>t)
require("treesitter-context").setup({ enable = false })

vim.keymap.set("n", "<leader>t", function()
	require("treesitter-context").toggle()
end, { desc = "Toggle Treesitter Context" })

vim.keymap.set("n", "<leader>T", function()
	require("treesitter-context").go_to_context(vim.v.count1)
end, { silent = true })
