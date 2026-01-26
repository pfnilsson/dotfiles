local CLAUDE_NAME_PATTERNS = { "claude", "devbox" }

local function is_claude_terminal_buf(buf)
	if vim.bo[buf].buftype ~= "terminal" then
		return false
	end
	local name = (vim.api.nvim_buf_get_name(buf) or ""):lower()
	for _, pat in ipairs(CLAUDE_NAME_PATTERNS) do
		if name:find(pat, 1, true) then
			return true
		end
	end
	return false
end

local function find_claude_terminal_win()
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
			local buf = vim.api.nvim_win_get_buf(win)
			if is_claude_terminal_buf(buf) then
				return tab, win
			end
		end
	end
end

local function claude_smart_toggle()
	local cur_tab = vim.api.nvim_get_current_tabpage()
	local cur_win = vim.api.nvim_get_current_win()
	local cur_buf = vim.api.nvim_win_get_buf(cur_win)

	-- From diff -> go to Claude, remember diff location
	if vim.wo.diff then
		vim.g._claude_last_diff = { tab = cur_tab, win = cur_win }

		local tab, win = find_claude_terminal_win()
		if tab and win then
			vim.api.nvim_set_current_tabpage(tab)
			vim.api.nvim_set_current_win(win)
		else
			vim.cmd("ClaudeCodeFocus")
		end
		return
	end

	-- From Claude terminal -> return to diff IF it still exists; otherwise fall back to normal toggle
	if is_claude_terminal_buf(cur_buf) and vim.g._claude_last_diff then
		local d = vim.g._claude_last_diff
		local tab_ok = d.tab and vim.api.nvim_tabpage_is_valid(d.tab)
		local win_ok = d.win and vim.api.nvim_win_is_valid(d.win)

		if tab_ok and win_ok then
			vim.api.nvim_set_current_tabpage(d.tab)
			vim.api.nvim_set_current_win(d.win)
			return
		else
			-- Diff was closed/rejected; clear stale state and proceed as normal
			vim.g._claude_last_diff = nil
		end
	end

	-- Normal behavior everywhere else
	vim.cmd("ClaudeCode")
end

return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	opts = {
		terminal_cmd = vim.fn.has("mac") == 1 and "devbox ai" or "claude",
		terminal = {
			split_width_percentage = 0.6,
			provider = "native",
		},
		diff_opts = {
			layout = "vertical",
			open_in_new_tab = true,
			hide_terminal_in_new_tab = true,
			keep_terminal_focus = false,
		},
	},
	config = true,
	keys = {
		{ "<F24>", claude_smart_toggle, mode = { "n", "i", "x", "t" }, desc = "Toggle Claude" },
		{ "<S-F12>", claude_smart_toggle, mode = { "n", "i", "x", "t" }, desc = "Toggle Claude" },
		{ "<leader>af", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: add file" },
		{
			"<leader>at",
			function()
				local l = vim.fn.line(".")
				vim.cmd(("ClaudeCodeAdd %% %d %d"):format(l, l))
			end,
			mode = "n",
			desc = "Claude: add this line",
		},
		{ "<leader>at", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
}
