local M = {}

-- Ensure ~/notes directory exists
local notes_dir = vim.fn.expand("~/notes")
if vim.fn.isdirectory(notes_dir) == 0 then
    vim.fn.mkdir(notes_dir, "p")
end

-- Internal state
M.notes   = {}  -- list of { name=string, buf=number, path=string }
M.current = nil -- index of last opened note
M.win_id  = nil -- floating window ID

-- Forward declarations
local create_buf, show_buf, buf_keymaps, save_all, get_note_buf

local nf  = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
-- 2) create a new highlight group that reuses that bg but gives us custom fg
vim.api.nvim_set_hl(0, "MyNotesFloat", {
    fg = "#E0B0FF",     -- your new text colour (lavender-pink)
    bg = nf.background, -- keep the same float background
})

-- Create or load a buffer for a given file path
function create_buf(path)
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, path)
    vim.api.nvim_buf_set_option(buf, "buftype", "")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "text")
    if vim.fn.filereadable(path) == 1 then
        local lines = vim.fn.readfile(path)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    end
    buf_keymaps(buf)
    return buf
end

-- Show or switch to a buffer in a floating window
function show_buf(buf)
    local H, W   = vim.o.lines, vim.o.columns
    local height = math.floor(H * 0.8)
    local width  = math.floor(W * 0.8)
    local row    = math.floor((H - height) / 2)
    local col    = math.floor((W - width) / 2)

    if not M.win_id or not vim.api.nvim_win_is_valid(M.win_id) then
        M.win_id = vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width    = width,
            height   = height,
            row      = row,
            col      = col,
            style    = "minimal",
            border   = "rounded",
        })
    else
        vim.api.nvim_win_set_buf(M.win_id, buf)
    end

    -- styling
    vim.api.nvim_win_set_option(M.win_id, "winhighlight",
        "Normal:MyNotesFloat,FloatBorder:FloatBorder"
    )
    vim.api.nvim_win_set_option(M.win_id, "number", true)
    vim.api.nvim_win_set_option(M.win_id, "relativenumber", true)

    -- enable wrapping only in the notes window
    vim.api.nvim_win_set_option(M.win_id, "wrap", true)
    vim.api.nvim_win_set_option(M.win_id, "linebreak", true)
    vim.api.nvim_win_set_option(M.win_id, "breakindent", true)

    -- update winbar
    local parts = {}
    for i, note in ipairs(M.notes) do
        local title = #note.name > 10 and note.name:sub(1, 10) .. "…" or note.name
        local hl    = (i == M.current) and "%#TabLineSel#" or "%#TabLine#"
        table.insert(parts, hl .. " " .. i .. ":" .. title .. " ")
    end
    table.insert(parts, "%#TabLineFill#")
    vim.api.nvim_win_set_option(M.win_id, "winbar", table.concat(parts))
end

function save_all()
    for _, note in ipairs(M.notes) do
        if note.buf and vim.api.nvim_buf_is_loaded(note.buf) then
            local lines = vim.api.nvim_buf_get_lines(note.buf, 0, -1, false)
            vim.fn.writefile(lines, note.path)
            vim.api.nvim_buf_set_option(note.buf, "modified", false)
        end
    end
end

-- Get or create buffer for a note by name
function get_note_buf(name)
    for i, note in ipairs(M.notes) do
        if note.name == name then
            if not note.buf then note.buf = create_buf(note.path) end
            return note.buf, i
        end
    end
    local path = notes_dir .. "/" .. name .. ".txt"
    local buf = create_buf(path)
    table.insert(M.notes, { name = name, buf = buf, path = path })
    return buf, #M.notes
end

-- Delete current note with confirmation
function M.delete_current()
    if not M.current then return end
    local note = M.notes[M.current]
    local choice = vim.fn.confirm("Delete note '" .. note.name .. "'?", "&Yes\n&No")
    if choice ~= 1 then return end
    -- if float showing this, close it
    if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
        local buf = vim.api.nvim_win_get_buf(M.win_id)
        if buf == note.buf then
            vim.api.nvim_win_close(M.win_id, true)
            M.win_id = nil
        end
    end
    -- delete file and buffer
    vim.fn.delete(note.path)
    if note.buf and vim.api.nvim_buf_is_loaded(note.buf) then
        vim.api.nvim_buf_delete(note.buf, { force = true })
    end
    -- remove from notes list
    table.remove(M.notes, M.current)
    if #M.notes == 0 then
        M.current = nil
    else
        M.current = math.min(M.current, #M.notes)
        local next_note = M.notes[M.current]
        show_buf(next_note.buf or create_buf(next_note.path))
    end
end

-- Buffer-local keymaps for note actions
function buf_keymaps(buf)
    local opts = { noremap = true, silent = true, buffer = buf }
    vim.keymap.set('n', '<leader>N', M.new_named, opts)
    vim.keymap.set('n', '<leader>to', M.next, opts)
    vim.keymap.set('n', '<leader>tp', M.prev, opts)
    vim.keymap.set('n', '<leader>w', '<cmd>write!<CR>', opts)
    vim.keymap.set('n', '<leader>d', M.delete_current, opts)
    -- quick access 1..9
    -- quick access 1..9
    for i = 1, math.min(#M.notes, 9) do
        vim.keymap.set('n', '<leader>' .. i, function()
            if M.notes[i] then
                -- use get_note_buf to avoid duplicate naming
                local buffer, idx = get_note_buf(M.notes[i].name)
                M.current = idx
                show_buf(buffer)
            end
        end, opts)
    end
end

-- Initialize notes list from existing files
local function init_notes()
    for _, file in ipairs(vim.fn.globpath(notes_dir, "*.txt", false, true)) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        table.insert(M.notes, { name = name, buf = nil, path = file })
    end
end
init_notes()

-- Open or toggle main note popup
function M.open_main()
    if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
        save_all()
        vim.api.nvim_win_close(M.win_id, true)
        M.win_id = nil
        return
    end
    if not M.current then
        _, M.current = get_note_buf("main")
    end
    local note = M.notes[M.current]
    show_buf(note.buf or create_buf(note.path))
end

-- Prompt to create/open a named note
function M.new_named()
    vim.ui.input({ prompt = "New note name: " }, function(name)
        if name and name ~= "" then
            local buf, idx = get_note_buf(name)
            M.current = idx
            show_buf(buf)
        end
    end)
end

-- Cycle to next note
function M.next()
    if not M.win_id or #M.notes < 2 then return end
    M.current = (M.current % #M.notes) + 1
    local note = M.notes[M.current]
    show_buf(note.buf or create_buf(note.path))
end

-- Cycle to previous note
function M.prev()
    if not M.win_id or #M.notes < 2 then return end
    M.current = ((M.current - 2) % #M.notes) + 1
    local note = M.notes[M.current]
    show_buf(note.buf or create_buf(note.path))
end

-- Global keymap: toggle notes popup
vim.keymap.set('n', '<leader>n', M.open_main, { noremap = true, silent = true })
-- Auto-save all notes on exit
vim.api.nvim_create_autocmd('VimLeavePre', { callback = save_all })

return M
