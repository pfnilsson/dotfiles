-- Why this exists: a transient Bazel disk-cache write race on multi-output codegen
-- actions can make the per-worktree gpd build abort. When it does, gopls silently
-- degrades to "no diagnostics / no completion" with no signal in the editor — the
-- only trace is buried in ~/.cache/gopackagesdriver/<hash>.log. This module reads
-- that log for the current worktree and exposes the last build outcome as a lualine
-- component so a failure is visible immediately. It takes no action on its own; when
-- it goes red, bounce the daemon (`:GpdStatus` prints the exact command) and reload.

local M = {}

local CACHE_DIR = (vim.env.XDG_CACHE_HOME or (vim.env.HOME .. "/.cache")) .. "/gopackagesdriver"

M.opts = {
	interval_ms = 4000, -- background poll cadence
	notify_on_fail = true, -- one-shot vim.notify when state transitions into failure
}

-- state: "fail" | "building" | "ok" | "off" | "none" | "idle" | "unknown"
--   fail     daemon is alive and its most recent build failed  (the actionable alarm)
--   building daemon is alive and a build is in flight
--   ok       daemon is alive and its most recent build succeeded
--   off      daemon is not running (killed / not yet spawned) — recovering, not a failure
M.state = "unknown"
M.log_path = nil

-- Reproduces scripts/gopackagesdriver.sh's worktree-hash + log/pid lookup. Reports the
-- last build outcome in the log tail, but ONLY as a live state when the daemon is
-- actually running — a dead daemon reads as "off" so a stale failure in the log (e.g.
-- right after you kill the daemon to recover) doesn't keep alarming. $1 = workspace dir.
local DETECT = [[
dir="$1"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/gopackagesdriver"
gitdir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null) || { echo none; exit 0; }
case "$gitdir" in /*) ;; *) gitdir="$dir/$gitdir" ;; esac
if command -v sha256sum >/dev/null 2>&1; then
  h=$(printf %s "$gitdir" | sha256sum | cut -c1-16)
else
  h=$(printf %s "$gitdir" | shasum -a 256 | cut -c1-16)
fi
log="$cache/$h.log"
pidf="$cache/$h.pid"
alive=no
if [ -f "$pidf" ]; then
  pid=$(tr -d '[:space:]' < "$pidf" 2>/dev/null)
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && alive=yes
fi
if [ ! -f "$log" ]; then echo none; printf '%s\n' "$log"; exit 0; fi
m=$(tail -n 1500 "$log" | grep -aoE "Build: completed,|Build did NOT complete successfully|Build: bazel build via target_pattern_file" | tail -n 1)
case "$m" in
  *"did NOT complete"*) outcome=fail ;;
  *"Build: completed,"*) outcome=ok ;;
  *"via target_pattern_file"*) outcome=building ;;
  *) outcome=idle ;;
esac
[ "$alive" = no ] && outcome=off
echo "$outcome"
printf '%s\n' "$log"
]]

local function lualine_refresh()
	local ok, lualine = pcall(require, "lualine")
	if ok then
		lualine.refresh()
	else
		pcall(vim.cmd, "redrawstatus")
	end
end

function M.refresh()
	if not vim.system then
		return
	end
	-- Timer callbacks fire in a fast event context where vim.fn.* is disallowed;
	-- bounce back onto the main loop before touching getcwd/notify/lualine.
	if vim.in_fast_event() then
		vim.schedule(M.refresh)
		return
	end
	local cwd = vim.fn.getcwd()
	vim.system({ "sh", "-c", DETECT, "sh", cwd }, { text = true }, function(obj)
		local out = vim.split(obj.stdout or "", "\n", { trimempty = true })
		local new_state = out[1] or "unknown"
		local log_path = out[2]
		vim.schedule(function()
			local prev = M.state
			M.state = new_state
			M.log_path = log_path
			-- Only nudge when a live, working daemon flips into failure — never on first
			-- poll (prev "unknown"), on reload, or while the daemon is down. Prevents spam.
			if M.opts.notify_on_fail and new_state == "fail" and (prev == "ok" or prev == "building") then
				vim.notify(
					"gpd build failed — Go LSP data may be stale.\nRun :GpdStatus for the daemon-bounce command.",
					vim.log.levels.WARN,
					{ title = "gopackagesdriver" }
				)
			end
			lualine_refresh()
		end)
	end)
end

local LABELS = {
	fail = "✗ gpd",
	building = "● gpd",
	ok = "✓ gpd",
	off = "○ gpd",
}

function M.text()
	-- LABELS covers fail/building/ok/off; none/idle/unknown fall through to "" (hidden).
	return LABELS[M.state] or ""
end

function M.color()
	local s = M.state
	if s == "fail" then
		return { fg = "#f38ba8", gui = "bold" } -- red
	elseif s == "building" then
		return { fg = "#f9e2af" } -- yellow
	elseif s == "ok" or s == "off" then
		return { fg = "#6c7086" } -- subtle grey
	end
	return nil
end

-- Returns a lualine component table; drop into any section's list.
function M.lualine_component()
	return {
		M.text,
		cond = function()
			return M.text() ~= ""
		end,
		color = M.color,
		on_click = function()
			M.show_details()
		end,
	}
end

-- :GpdStatus — print the log path, the daemon-bounce command, and the last
-- few build-relevant log lines so a red indicator is immediately actionable.
function M.show_details()
	M.refresh()
	local lines = { "gpd state: " .. M.state }
	if M.log_path then
		table.insert(lines, "log: " .. M.log_path)
		local hash = M.log_path:match("([^/]+)%.log$")
		if hash then
			-- Bounce = kill the daemon (it respawns + rebuilds, clearing the flake), then reload nvim.
			local pid_file = CACHE_DIR .. "/" .. hash .. ".pid"
			local pid
			local f = io.open(pid_file, "r")
			if f then
				pid = (f:read("*a") or ""):gsub("%s+", "")
				f:close()
			end
			if pid and pid ~= "" then
				table.insert(lines, "bounce: kill " .. pid .. "   (then reload nvim)")
			end
		end
		local tail = vim.fn.systemlist({
			"sh",
			"-c",
			'tail -n 200 "$1" | grep -aE "Build: |did NOT complete|INFLIGHT START" | tail -n 8',
			"sh",
			M.log_path,
		})
		if #tail > 0 then
			table.insert(lines, "--- recent ---")
			vim.list_extend(lines, tail)
		end
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "gopackagesdriver" })
end

function M.setup(opts)
	M.opts = vim.tbl_extend("force", M.opts, opts or {})

	vim.api.nvim_create_user_command("GpdStatus", function()
		M.show_details()
	end, { desc = "Show gopackagesdriver build health for this worktree" })

	local grp = vim.api.nvim_create_augroup("GpdStatus", { clear = true })
	vim.api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
		group = grp,
		callback = function()
			M.refresh()
		end,
	})
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = grp,
		pattern = { "*.go", "BUILD.bazel", "*.bzl" },
		callback = function()
			-- a save often triggers a gpd re-query; re-check shortly after
			vim.defer_fn(M.refresh, 1500)
		end,
	})

	if M._timer then
		M._timer:stop()
	end
	M._timer = vim.uv.new_timer()
	M._timer:start(500, M.opts.interval_ms, function()
		M.refresh()
	end)
end

return M
