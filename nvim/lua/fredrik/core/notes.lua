-- Notes.nvim plugin
local M = {}

-- Ensure ~/notes directory exists
local notes_dir = vim.fn.expand("~/.notes")
if vim.fn.isdirectory(notes_dir) == 0 then
	vim.fn.mkdir(notes_dir, "p")
end

-- Internal state
M.notes = {} -- list of { name=string, buf=number, path=string }
M.current = nil -- index of last opened note
M.win_id = nil -- floating window ID

-- Text color
vim.api.nvim_set_hl(0, "MyNotesFloat", { fg = "#E0B0FF" })

-- Parse a filename into numeric prefix and display name
local function parse_file(path)
	local fname = vim.fn.fnamemodify(path, ":t:r")
	-- match prefix like "01_Note Name"
	local num, name = fname:match("^(%d+)_([%w%s_%-%p]+)$")
	if num then
		return tonumber(num), name, path
	else
		-- files without prefix go last
		return math.huge, fname, path
	end
end

-- Rescan notes directory, sort by prefix, and rebuild M.notes preserving existing buffers
local function rescan_notes()
	local parsed = {}
	-- collect and parse files
	for _, file in ipairs(vim.fn.globpath(notes_dir, "*.txt", false, true)) do
		local num, name, path = parse_file(file)
		table.insert(parsed, { num = num, name = name, path = path })
	end
	table.sort(parsed, function(a, b)
		return a.num < b.num
	end)
	-- rebuild notes list, preserving buffers for existing paths
	local new_notes = {}
	for _, item in ipairs(parsed) do
		local buf = nil
		for _, note in ipairs(M.notes) do
			if note.path == item.path then
				buf = note.buf
				break
			end
		end
		table.insert(new_notes, { name = item.name, buf = buf, path = item.path })
	end
	M.notes = new_notes
end

-- Compute next numeric prefix for a new note
local function next_prefix()
	local max = 0
	for _, file in ipairs(vim.fn.globpath(notes_dir, "*.txt", false, true)) do
		local num = file:match(notes_dir .. "/(%d+)_")
		num = tonumber(num) or 0
		if num > max then
			max = num
		end
	end
	return max + 1
end

-- Create or load a buffer for a given file path
local function create_buf(path)
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_buf_set_name(buf, path)
	vim.bo[buf].buftype = ""
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "text"
	if vim.fn.filereadable(path) == 1 then
		local lines = vim.fn.readfile(path)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end
	M.buf_keymaps(buf)
	return buf
end

-- Show or switch to a buffer in a floating window, reloading and reapplying keymaps
local function show_buf(buf)
	local path = vim.api.nvim_buf_get_name(buf)
	if vim.fn.filereadable(path) == 1 and not vim.api.nvim_get_option_value("modified", { buf = buf }) then
		local lines = vim.fn.readfile(path)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end
	M.buf_keymaps(buf)

	local H, W = vim.o.lines, vim.o.columns
	local height = math.floor(H * 0.8)
	local width = math.floor(W * 0.8)
	local row = math.floor((H - height) / 2)
	local col = math.floor((W - width) / 2)

	if not M.win_id or not vim.api.nvim_win_is_valid(M.win_id) then
		M.win_id = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
		})
	else
		vim.api.nvim_win_set_buf(M.win_id, buf)
	end

	vim.api.nvim_set_option_value("winhighlight", "Normal:MyNotesFloat,FloatBorder:FloatBorder", { win = M.win_id })
	vim.api.nvim_set_option_value("number", true, { win = M.win_id })
	vim.api.nvim_set_option_value("relativenumber", true, { win = M.win_id })
	vim.api.nvim_set_option_value("wrap", true, { win = M.win_id })
	vim.api.nvim_set_option_value("linebreak", true, { win = M.win_id })
	vim.api.nvim_set_option_value("breakindent", true, { win = M.win_id })

	-- update winbar with display names
	local parts = {}
	for i, note in ipairs(M.notes) do
		local title = #note.name > 10 and note.name:sub(1, 10) .. "…" or note.name
		local hl = (i == M.current) and "%#TabLineSel#" or "%#TabLine#"
		table.insert(parts, hl .. " " .. i .. ":" .. title .. " ")
	end
	table.insert(parts, "%#TabLineFill#")
	vim.wo[M.win_id].winbar = table.concat(parts)

	for i = 1, 9 do
		pcall(vim.keymap.del, "n", "<leader>" .. i, { buffer = buf })
	end

	-- recreate them freshly, pointing at each note
	for i, note in ipairs(M.notes) do
		if i > 9 then
			break
		end
		vim.keymap.set("n", "<leader>" .. i, function()
			local b, idx = M.get_note_buf(note.name)
			M.current = idx
			show_buf(b)
		end, { noremap = true, silent = true, buffer = buf })
	end
end

-- Save all open note buffers back to disk
local function save_all()
	for _, note in ipairs(M.notes) do
		if note.buf and vim.api.nvim_buf_is_loaded(note.buf) then
			-- switch into the buffer’s context so that `:write` uses its name
			vim.api.nvim_buf_call(note.buf, function()
				-- write without triggering file-changed warnings or autocommands
				vim.cmd("noautocmd silent! write!")
				-- mark the buffer as clean
				vim.bo[note.buf].modified = false
			end)
		end
	end
end

-- Get or create buffer for a note by display name
function M.get_note_buf(name)
	for i, note in ipairs(M.notes) do
		if note.name == name then
			if not note.buf then
				note.buf = create_buf(note.path)
			end
			return note.buf, i
		end
	end
	return nil, nil
end

-- Buffer-local keymaps for note actions
function M.buf_keymaps(buf)
	local opts = { noremap = true, silent = true, buffer = buf }
	vim.keymap.set("n", "<leader>N", M.new_named, opts)
	vim.keymap.set("n", "<leader>tn", M.next, opts)
	vim.keymap.set("n", "<leader>tp", M.prev, opts)
	vim.keymap.set("n", "<leader>w", "<cmd>write!<CR>", opts)
	vim.keymap.set("n", "<leader>D", M.delete_current, opts)
end

-- Delete current note and renumber remains
function M.delete_current()
	if not M.current then
		return
	end
	local note = M.notes[M.current]
	-- confirm deletion
	local choice = vim.fn.confirm("Delete note '" .. note.name .. "'?", "&Yes\n&No")
	if choice ~= 1 then
		return
	end

	-- close float if showing this buffer
	if
		M.win_id
		and vim.api.nvim_win_is_valid(M.win_id)
		and vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(M.win_id)) == note.path
	then
		vim.api.nvim_win_close(M.win_id, true)
		M.win_id = nil
	end

	-- delete file
	vim.fn.delete(note.path)
	-- delete buffer
	if note.buf and vim.api.nvim_buf_is_loaded(note.buf) then
		vim.api.nvim_buf_delete(note.buf, { force = true })
	end

	-- renumber remaining files
	rescan_notes()
	for idx, item in ipairs(M.notes) do
		local num = string.format("%02d", idx)
		local newname = notes_dir .. "/" .. num .. "_" .. item.name .. ".txt"
		if item.path ~= newname then
			vim.fn.rename(item.path, newname)
			item.path = newname
		end
	end
	-- final sync
	rescan_notes()
	M.current = (#M.notes > 0) and math.min(M.current, #M.notes) or nil
end

-- Open or toggle main note popup
function M.open_main()
	rescan_notes()
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		save_all()
		vim.api.nvim_win_close(M.win_id, true)
		M.win_id = nil
		return
	end
	if not M.current then
		M.current = (#M.notes > 0) and 1 or nil
	end

	if M.current then
		local buf, idx = M.get_note_buf(M.notes[M.current].name)
		M.current = idx
		show_buf(buf)
	end
end

-- Prompt to create/open a named note with new prefix
function M.new_named()
	vim.ui.input({ prompt = "New note name: " }, function(name)
		if name and name ~= "" then
			rescan_notes()
			local prefix = next_prefix()
			local num = string.format("%02d", prefix)
			local fname = notes_dir .. "/" .. num .. "_" .. name .. ".txt"
			vim.fn.writefile({}, fname)
			-- show new note
			rescan_notes()
			for i, note in ipairs(M.notes) do
				if note.path == fname then
					M.current = i
					local buf, idx = M.get_note_buf(note.name)
					M.current = idx
					show_buf(buf)
					break
				end
			end
		end
	end)
end

-- Cycle to next note
function M.next()
	if not M.win_id or #M.notes < 2 then
		return
	end
	M.current = (M.current % #M.notes) + 1
	local buf, idx = M.get_note_buf(M.notes[M.current].name)
	M.current = idx
	show_buf(buf)
end

-- Cycle to previous note
function M.prev()
	if not M.win_id or #M.notes < 2 then
		return
	end
	M.current = ((M.current - 2) % #M.notes) + 1
	local buf, idx = M.get_note_buf(M.notes[M.current].name)
	M.current = idx
	show_buf(buf)
end

-- Global keymaps
vim.keymap.set("n", "<leader>n", M.open_main, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>N", M.new_named, { noremap = true, silent = true })

-- Auto-save all notes on exit
vim.api.nvim_create_autocmd("VimLeavePre", { callback = save_all })

-- Initial setup
rescan_notes()

return M
