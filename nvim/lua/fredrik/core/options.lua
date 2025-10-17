-- Enable line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Set indentation
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 4 -- Number of spaces for each indentation step
vim.opt.tabstop = 4 -- Number of spaces that a <Tab> counts for
vim.opt.softtabstop = 4
vim.opt.smartindent = true

-- Disable unused providers
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

-- Leave at least 5 lines above/below cursor
vim.opt.scrolloff = 5

-- no line wrapping
vim.opt.wrap = false

-- store undo history
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- reload externally changed files
vim.opt.autoread = true

-- don't use swap files or backup
vim.opt.swapfile = false
vim.opt.backup = false

-- use all the colors
vim.opt.termguicolors = true

-- update every 50ms instead of default 4000ms
vim.opt.updatetime = 50

-- use single statusline
vim.opt.laststatus = 3

-- Enable virtual text for diagnostics
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
})
