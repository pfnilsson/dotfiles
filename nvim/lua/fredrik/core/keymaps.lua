-----------------------------------------------------------
-- Leader Key Setup
-----------------------------------------------------------
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local opts           = { noremap = true, silent = true }

-- Disable <Space> as a key
vim.keymap.set("n", "<Space>", "<Nop>", opts)
vim.keymap.set("x", "<Space>", "<Nop>", opts)
vim.keymap.set("o", "<Space>", "<Nop>", opts)

-----------------------------------------------------------
-- General Keymaps
-----------------------------------------------------------

-- Diagnostic navigation

-- Go to previous diagnostic
vim.keymap.set("n", "Åd", function()
    vim.diagnostic.goto_prev()
end, { desc = "Go to previous diagnostic" })

-- Go to next diagnostic
vim.keymap.set("n", "åd", function()
    vim.diagnostic.goto_next()
end, { desc = "Go to next diagnostic" })

-- Go to previous error
vim.keymap.set("n", "Åe", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Go to previous error" })

-- Go to next error
vim.keymap.set("n", "åe", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Go to next error" })

-- Go to previous warning
vim.keymap.set("n", "Åw", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Go to previous warning" })

-- Go to next warning
vim.keymap.set("n", "åw", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Go to next warning" })

-- Go to previous hint
vim.keymap.set("n", "Åh", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.HINT })
end, { desc = "Go to previous hint" })

-- Go to next hint
vim.keymap.set("n", "åh", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.HINT })
end, { desc = "Go to next hint" })

-- Go to previous information
vim.keymap.set("n", "Åi", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.INFO })
end, { desc = "Go to previous information" })

-- Go to next information
vim.keymap.set("n", "åi", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.INFO })
end, { desc = "Go to next information" })

-- List all diagnostics via Telescope
vim.keymap.set("n", "<leader>ld", ":Telescope diagnostics<CR>", { desc = "List diagnostics" })


-- View open buffers with Telescope
vim.keymap.set(
    "n",
    "<leader>h",
    "<cmd>Telescope buffers sort_mru=true sort_lastused=true initial_mode=normal<cr>",
    { desc = "[P] Open Telescope buffers" }
)
-- Save the file
vim.keymap.set("n", "<leader>w", ":write<CR>", { noremap = true, silent = true, desc = "Save File" })
vim.keymap.set('n', '<leader>W', ':wa<CR>', { noremap = true, silent = true, desc = "Save All" })

-- Remap End of Line to be Shift+4 like on a US keyboard layout
vim.keymap.set({ 'n', 'v', 'o' }, '€', '$', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v', 'o' }, '¤', '$', { noremap = true, silent = true })

-- Remap [ and ] to Å and å to match US keyboard shortcuts
vim.keymap.set('n', 'å', ']') -- Normal mode remap for å
vim.keymap.set('n', 'Å', '[') -- Normal mode remap for Å
vim.keymap.set('v', 'å', ']') -- Visual mode remap for å
vim.keymap.set('v', 'Å', '[') -- Visual mode remap for Å

-- Remap ^ to " to make it easier to press on a swedish keyboard
vim.keymap.set('n', '"', '^', { noremap = true, silent = true })
vim.keymap.set({ 'n', 'v', 'o' }, '"', '^', { noremap = true, silent = true })

-- Remap ~ to § to use the same key as US keyboard
vim.keymap.set('n', '§', '~', { noremap = true, silent = true })

-- Fix all & Organize imports
local function fixAll()
    vim.lsp.buf.code_action({
        context = { only = { "source.fixAll" } },
        apply = true,
        async = false,
    })
end
vim.keymap.set("n", "<leader>lf", fixAll, { desc = "Fix All" })

local function organizeImports()
    vim.lsp.buf.code_action({
        context = { only = { "source.organizeImports" } },
        apply = true,
        async = false,
    })
end
vim.keymap.set("n", "<leader>lo", organizeImports, { desc = "Organize Imports" })

-- See available code actions
vim.keymap.set({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, { desc = "See available code actions" })

-- Unbind F1
vim.keymap.set("n", "<F1>", "<nop>", { noremap = true, silent = true })

-- Allowing moving selection up and down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Cursor stays in place after line join
vim.keymap.set("n", "J", "mzJ`z")

-- Half page up/down centers on cursor
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Search matches stay centered when going through
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- <leader>d delete into void registry
vim.keymap.set({ "n", "v" }, "<leader>d", "\"_d")

-- <leader>y/Y to yank to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+y$]])

-- <leader>p/P to paste from system clipboard
vim.keymap.set("n", "<leader>p", [["+p]])
vim.keymap.set("n", "<leader>P", '"+]p')

-- Paste over highlight without losing current clipboard value
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Remap Y to y$
vim.keymap.set("n", "Y", "y$", { noremap = true, silent = true })

-- <leader>o/O to insert line below/above and stay in normal mode
vim.keymap.set("n", "<leader>o", "mzo<Esc>`z")
vim.keymap.set("n", "<leader>O", "mzO<Esc>`z")

-- make sure C-c is equivalent to <Esc> inserting in visual block mode
vim.keymap.set("i", "<C-c>", "<Esc")

-- disable entry in to Ex mode
vim.keymap.set("n", "Q", "<nop>")

-- C-l move right in insert mode
vim.keymap.set('i', '<C-l>', '<Right>', { noremap = true, silent = true })

-- Quickfix binds
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")

-- Function to toggle the Quickfix List
local function toggle_quickfix()
    -- Iterate through all open windows
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == 'quickfix' then
            -- If Quickfix window is found, close it
            vim.api.nvim_win_close(win, true)
            return
        end
    end
    -- If Quickfix window is not open, open it
    vim.cmd('copen')
end
vim.keymap.set("n", "<leader>q", toggle_quickfix, { noremap = true, silent = true, desc = "Toggle Quickfix list" })

-- some go boiler plate help

-- <leader>ee to insert if err != nil { return err } block (for go)
vim.keymap.set("n", "<leader>ee", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>",
    { desc = "Insert if err != nil {return err}" })

-- <leader>ef to insert if err != nil {log.Fatalf} block
vim.keymap.set(
    "n",
    "<leader>ef",
    "oif err != nil {<CR>}<Esc>Olog.Fatalf(\"Error: %v\\n\", err)<Esc>jj",
    { desc = "Insert if err != nil {log.Fatalf} block" }
)

-- <leader> ew to insert if err != nil with wrapped return err
vim.keymap.set(
    "n",
    "<leader>ew",
    "oif err != nil {<CR>}<Esc>Oreturn fmt.Errorf(\"%w\", err)<Esc>F\"hhi",
    { desc = "Insert if err != nil with wrapped return err" }
)

-- Rebind <C-o> since some plugin removes it
vim.keymap.set('i', '<C-o>', '<C-o>', { noremap = true, silent = true })

-- <C-d> deletes a character to the right in insert mode (like <Del>)
vim.keymap.set('i', '<C-d>', '<C-o>x', { noremap = true, silent = true })
