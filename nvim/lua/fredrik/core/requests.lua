local M = {}

local uv = vim.uv or vim.loop

-- Directory for request collections
local requests_dir = vim.fn.expand("~/.requests")
if vim.fn.isdirectory(requests_dir) == 0 then
	vim.fn.mkdir(requests_dir, "p")
end

M.win_id = nil -- main request editor window
M.result_win_id = nil -- result popup window
M.env = {} -- extra env vars passed to requests

-- Load environment variables from .env file in cwd if it exists
local function load_env_file()
	local env_path = vim.fn.getcwd() .. "/.env"
	if vim.fn.filereadable(env_path) ~= 1 then
		return
	end

	local lines = vim.fn.readfile(env_path)
	for _, line in ipairs(lines) do
		-- Skip empty lines and comments
		local trimmed = line:match("^%s*(.-)%s*$")
		if trimmed ~= "" and not trimmed:match("^#") then
			-- Match KEY=VALUE or export KEY=VALUE (value can be quoted or unquoted)
			local key, value = trimmed:match("^export%s+([%w_]+)%s*=%s*(.*)$")
			if not key then
				key, value = trimmed:match("^([%w_]+)%s*=%s*(.*)$")
			end
			if key and value then
				-- Strip surrounding quotes if present
				value = value:match("^[\"'](.*)[\"']$") or value
				M.env[key] = value
			end
		end
	end
end

local env_loaded = false
local function ensure_env_loaded()
	if env_loaded then
		return
	end
	env_loaded = true
	load_env_file()
end

----------------------------------------------------------------------
-- Generic helpers
----------------------------------------------------------------------

-- Sanitize a name into a safe filename (no extension)
local function sanitize_name(name)
	name = name:gsub("%s+", "_") -- whitespace -> underscores
	name = name:gsub("[^%w%._%-]", "") -- strip weird chars
	if name == "" then
		name = "request"
	end
	return name
end

-- Small helper to show a status message in the command-line
local function echo_status(msg)
	vim.api.nvim_echo({ { msg, "ModeMsg" } }, false, {})
end

-- List all readable files in requests_dir
local function list_request_files()
	local files = vim.fn.globpath(requests_dir, "*", false, true)
	local items = {}

	for _, path in ipairs(files) do
		if vim.fn.filereadable(path) == 1 then
			table.insert(items, {
				label = vim.fn.fnamemodify(path, ":t"), -- filename (no extension)
				path = path,
				new = false,
			})
		end
	end

	return items
end

-- Save a buffer if it's a request file under ~/.requests and modified
local function maybe_save_request_buf(buf)
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local path = vim.api.nvim_buf_get_name(buf)
	if path == "" or path:sub(1, #requests_dir) ~= requests_dir then
		return
	end

	local is_modified = vim.api.nvim_get_option_value("modified", { buf = buf })
	local is_modifiable = vim.api.nvim_get_option_value("modifiable", { buf = buf })

	if is_modifiable and is_modified then
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("silent write")
		end)
	end
end

----------------------------------------------------------------------
-- Window helpers
----------------------------------------------------------------------

local function open_centered_float(buf, extra_opts)
	local H, W = vim.o.lines, vim.o.columns
	local height = math.floor(H * 0.8)
	local width = math.floor(W * 0.8)
	local row = math.floor((H - height) / 2)
	local col = math.floor((W - width) / 2)

	local win_opts = vim.tbl_extend("force", {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	}, extra_opts or {})

	return vim.api.nvim_open_win(buf, true, win_opts)
end

function M.close_window()
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		local buf = vim.api.nvim_win_get_buf(M.win_id)

		-- Save current request buffer if needed
		maybe_save_request_buf(buf)

		vim.api.nvim_win_close(M.win_id, true)
	end
	M.win_id = nil
end

function M.close_result_window()
	if M.result_win_id and vim.api.nvim_win_is_valid(M.result_win_id) then
		vim.api.nvim_win_close(M.result_win_id, true)
	end
	M.result_win_id = nil
end

-- Close both request + result windows if they exist
function M.close_all()
	M.close_result_window()
	M.close_window()
end

----------------------------------------------------------------------
-- Result buffer: filetype detection + jq formatting
----------------------------------------------------------------------

local function detect_result_filetype(lines)
	if not lines or #lines == 0 then
		return nil
	end

	local text = table.concat(lines, "\n")
	local sample = text:sub(1, 512)

	-- first non-empty line
	local first_non_empty
	for _, l in ipairs(lines) do
		local trimmed = l:match("^%s*(.-)%s*$")
		if trimmed ~= "" then
			first_non_empty = trimmed
			break
		end
	end
	if not first_non_empty then
		return nil
	end

	local lower_sample = sample:lower()
	local lower_first = first_non_empty:lower()

	-- HTML
	if lower_sample:find("<!doctype html", 1, true) or lower_sample:find("<html", 1, true) then
		return "html"
	end

	-- XML (avoid misclassifying HTML as XML)
	if lower_first:match("^%s*%<%?xml") or lower_first:match("^%s*%<[%w_:-]+[%s>]") then
		if not lower_sample:find("<html", 1, true) then
			return "xml"
		end
	end

	-- JSON (object/array at top)
	if lower_first:match("^%s*[%[{]") then
		return "json"
	end

	-- YAML-ish
	if lower_first:match("^%s*%-%-%-") or lower_first:match("^%s*[%w_%-]+%s*:") then
		return "yaml"
	end

	return nil
end

local function format_with_jq(stdout)
	-- Try to run: echo "$stdout" | jq .
	local formatted = vim.fn.system({ "jq", "." }, stdout)

	-- If jq is missing or the output isn't valid JSON, just return the original
	if vim.v.shell_error ~= 0 or formatted == "" then
		return stdout
	end

	return formatted
end

local function open_result_float(lines)
	M.close_result_window()

	local buf = vim.api.nvim_create_buf(false, true) -- listed=false, scratch=true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local ft = detect_result_filetype(lines)
	if ft then
		vim.bo[buf].filetype = ft
	end

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	M.result_win_id = open_centered_float(buf)

	-- buffer-local 'q' to close results window
	vim.keymap.set("n", "q", function()
		M.close_result_window()
	end, { buffer = buf, noremap = true, silent = true })
end

----------------------------------------------------------------------
-- Request separators and block parsing
----------------------------------------------------------------------

-- Parse a separator line: return (is_separator, label_or_nil)
-- Matches lines like:
--   "###"
--   "### get users"
--   "   ###   login-request   "
local function parse_separator(line)
	local raw = line:match("^%s*###%s*(.-)%s*$")
	if not raw then
		return false, nil
	end
	if raw == "" then
		return true, nil
	end
	return true, raw
end

-- If cursor is on a separator line, move it to the nearest non-separator,
-- preferring the block below.
local function adjust_cursor_off_separator(lines, cur_line)
	local is_sep_here = parse_separator(lines[cur_line])
	if not is_sep_here then
		return cur_line
	end

	-- try below
	for i = cur_line + 1, #lines do
		local is_sep = parse_separator(lines[i])
		if not is_sep and lines[i]:match("%S") then
			return i
		end
	end

	-- try above
	for i = cur_line - 1, 1, -1 do
		local is_sep = parse_separator(lines[i])
		if not is_sep and lines[i]:match("%S") then
			return i
		end
	end

	return cur_line
end

-- Find the bounds of the block around cur_line.
-- Returns: start_idx, stop_idx, sep_before_idx (or nil)
local function find_block_bounds(lines, cur_line)
	local sep_before = nil
	for i = cur_line - 1, 1, -1 do
		local is_sep = parse_separator(lines[i])
		if is_sep then
			sep_before = i
			break
		end
	end

	local sep_after = nil
	for i = cur_line + 1, #lines do
		local is_sep = parse_separator(lines[i])
		if is_sep then
			sep_after = i
			break
		end
	end

	local start = sep_before and (sep_before + 1) or 1
	local stop = sep_after and (sep_after - 1) or #lines

	if start > stop then
		return nil, nil, nil
	end

	return start, stop, sep_before
end

-- Extract and trim a block from [start, stop].
local function extract_block(lines, start, stop)
	local block = {}
	for i = start, stop do
		table.insert(block, lines[i])
	end

	-- Trim leading/trailing completely blank lines inside the block
	while #block > 0 and block[1]:match("^%s*$") do
		table.remove(block, 1)
	end
	while #block > 0 and block[#block]:match("^%s*$") do
		table.remove(block, #block)
	end

	if #block == 0 then
		return nil
	end

	return block
end

local function get_block_label(lines, sep_before_idx)
	if not sep_before_idx then
		return nil
	end
	local _, label = parse_separator(lines[sep_before_idx])
	return label
end

-- Returns: block_lines, block_label_or_nil
local function get_current_request_block(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	if #lines == 0 then
		return nil, nil
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local cur_line = cursor[1] -- 1-based

	cur_line = adjust_cursor_off_separator(lines, cur_line)

	local start, stop, sep_before = find_block_bounds(lines, cur_line)
	if not start or not stop then
		return nil, nil
	end

	local block = extract_block(lines, start, stop)
	if not block then
		return nil, nil
	end

	local label = get_block_label(lines, sep_before)
	return block, label
end

----------------------------------------------------------------------
-- Command execution helpers
----------------------------------------------------------------------

local function build_result_lines(stdout, stderr, code)
	local out = {}

	if stdout and stdout ~= "" then
		-- Let jq pretty-print if it can
		local formatted = format_with_jq(stdout)
		local stdout_lines = vim.split(formatted, "\n", { plain = true })
		vim.list_extend(out, stdout_lines)
	end

	if code and code ~= 0 and stderr and stderr ~= "" then
		if #out > 0 then
			table.insert(out, "")
			table.insert(out, "----- stderr -----")
		end
		local parts = vim.split(stderr, "\n", { plain = true })
		vim.list_extend(out, parts)
	end

	if code and code ~= 0 then
		table.insert(out, "")
		table.insert(out, string.format("[exit code %d]", code))
	end

	if #out == 0 then
		out = { "[no output]" }
	end

	return out
end

-- Run a shell command, measure time, and invoke cb(stdout, stderr, code, elapsed_sec)
local function run_shell_command(cmd, env, cb)
	env = env or {}

	if vim.system then
		local start_ns = uv and uv.hrtime() or nil

		vim.system({ "sh", "-c", cmd }, {
			text = true,
			env = env,
		}, function(res)
			vim.schedule(function()
				local elapsed_sec
				if start_ns and uv then
					local diff = uv.hrtime() - start_ns
					elapsed_sec = diff / 1e9
				end
				cb(res.stdout or "", res.stderr or "", res.code or 0, elapsed_sec)
			end)
		end)
	else
		-- Synchronous fallback (env from env table is *not* injected here)
		local start_ns = uv and uv.hrtime() or nil
		local stdout = table.concat(vim.fn.systemlist(cmd), "\n")
		local code = vim.v.shell_error
		local elapsed_sec
		if start_ns and uv then
			local diff = uv.hrtime() - start_ns
			elapsed_sec = diff / 1e9
		end
		cb(stdout, "", code, elapsed_sec)
	end
end

----------------------------------------------------------------------
-- Request editor window
----------------------------------------------------------------------

-- Show current env vars
function M.show_env()
	local keys = vim.tbl_keys(M.env)
	if #keys == 0 then
		local env_path = vim.fn.getcwd() .. "/.env"
		echo_status("[requests] no env vars set (looking for " .. env_path .. ")")
		return
	end

	table.sort(keys)
	local lines = {}
	for _, k in ipairs(keys) do
		table.insert(lines, string.format("%s=%s", k, M.env[k]))
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

-- Add an env var via <leader>rv inside the request window
function M.add_env_var()
	vim.ui.input({ prompt = "Env var name: " }, function(name)
		if not name or name == "" then
			return
		end
		name = name:gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then
			return
		end

		vim.ui.input({ prompt = string.format("Env var value (%s): ", name) }, function(value)
			if value == nil then
				return
			end
			M.env[name] = tostring(value)
			echo_status(string.format("[requests] set %s", name))
		end)
	end)
end

local function open_file_in_float(path)
	ensure_env_loaded()
	local buf = vim.fn.bufadd(path)
	vim.fn.bufload(buf)

	if vim.fn.filereadable(path) == 1 then
		local lines = vim.fn.readfile(path)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	end

	vim.bo[buf].filetype = "sh"

	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		-- Save the buffer currently shown in the request window before switching
		local old_buf = vim.api.nvim_win_get_buf(M.win_id)
		maybe_save_request_buf(old_buf)

		vim.api.nvim_win_set_buf(M.win_id, buf)
	else
		M.win_id = open_centered_float(buf)
	end

	-- Buffer-local keymap to add env vars from inside request window
	vim.keymap.set("n", "<leader>rv", M.add_env_var, { buffer = buf, noremap = true, silent = true })
end

----------------------------------------------------------------------
-- Creating and deleting request collections
----------------------------------------------------------------------

function M.new_request_collection()
	vim.ui.input({ prompt = "New request collection name: " }, function(name)
		if not name or name == "" then
			return
		end

		local base = sanitize_name(name)
		local fname = base
		local path = requests_dir .. "/" .. fname

		local counter = 1
		while vim.fn.filereadable(path) == 1 do
			fname = string.format("%s_%d", base, counter)
			path = requests_dir .. "/" .. fname
			counter = counter + 1
		end

		vim.fn.writefile({}, path)

		open_file_in_float(path)
	end)
end

function M.delete_current_file()
	local buf = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(buf)

	if path == "" or path:sub(1, #requests_dir) ~= requests_dir then
		vim.notify("Current buffer is not a request file under " .. requests_dir, vim.log.levels.WARN)
		return
	end

	local fname = vim.fn.fnamemodify(path, ":t")
	local choice = vim.fn.confirm("Delete request file '" .. fname .. "'?", "&Yes\n&No", 2)
	if choice ~= 1 then
		return
	end

	-- Delete file from disk
	vim.fn.delete(path)

	-- If the request window is showing this buffer, close it (without saving)
	if M.win_id and vim.api.nvim_win_is_valid(M.win_id) then
		local wbuf = vim.api.nvim_win_get_buf(M.win_id)
		if wbuf == buf then
			vim.api.nvim_win_close(M.win_id, true)
			M.win_id = nil
		end
	end

	-- Delete the buffer
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_delete(buf, { force = true })
	end

	echo_status(string.format("[requests] deleted %s", fname))
end

----------------------------------------------------------------------
-- Execute current request block and show result
----------------------------------------------------------------------

function M.send_current()
	local buf = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(buf)

	if path == "" or path:sub(1, #requests_dir) ~= requests_dir then
		vim.notify("Not a request file under " .. requests_dir, vim.log.levels.WARN)
		return
	end

	local block_lines, label = get_current_request_block(buf)
	if not block_lines then
		vim.notify("Current request block is empty (no lines between ### separators)", vim.log.levels.WARN)
		return
	end

	local cmd = table.concat(block_lines, "\n")

	local label_part = ""
	if label and label ~= "" then
		label_part = string.format(" [%s]", label)
	end

	-- Indicate that we are sending
	echo_status(string.format("[requests] sending%s...", label_part))

	run_shell_command(cmd, M.env, function(stdout, stderr, code, elapsed_sec)
		local out = build_result_lines(stdout, stderr, code)

		local elapsed_str = ""
		if elapsed_sec and elapsed_sec > 0 then
			elapsed_str = string.format(" in %.2fs", elapsed_sec)
		end

		echo_status(string.format("[requests] done%s%s (exit code %d)", label_part, elapsed_str, code or 0))
		open_result_float(out)
	end)
end

----------------------------------------------------------------------
-- Picker
----------------------------------------------------------------------

function M.open_requests()
	local items = list_request_files()

	table.insert(items, 1, {
		label = "+ New request collection",
		path = nil,
		new = true,
	})

	vim.ui.select(items, {
		prompt = "Select request collection",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if not choice then
			return
		end
		if choice.new then
			M.new_request_collection()
		else
			open_file_in_float(choice.path)
		end
	end)
end

----------------------------------------------------------------------
-- Keymaps
----------------------------------------------------------------------

vim.keymap.set("n", "<leader>re", function()
	M.open_requests()
end, { noremap = true, silent = true, desc = "Requests: open collection picker" })

vim.keymap.set("n", "<leader>rq", function()
	M.close_all()
end, { noremap = true, silent = true, desc = "Requests: close request + response" })

vim.keymap.set("n", "<leader>rs", function()
	M.send_current()
end, { noremap = true, silent = true, desc = "Requests: send current block" })

vim.keymap.set("n", "<leader>rd", function()
	M.delete_current_file()
end, { noremap = true, silent = true, desc = "Requests: delete current file" })

vim.keymap.set("n", "<leader>rV", function()
	M.show_env()
end, { noremap = true, silent = true, desc = "Requests: show env vars" })
return M
