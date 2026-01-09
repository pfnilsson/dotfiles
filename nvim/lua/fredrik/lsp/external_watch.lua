local M = {}

local uv = vim.uv

local roots = {}

local DEFAULT_IGNORED_DIRS = {
	[".git"] = true,
	["node_modules"] = true,
	["vendor"] = true,
	[".hg"] = true,
	[".svn"] = true,
}

local FT_MAP = {
	go = { ext = { "go" }, name = { "go.mod", "go.sum", "go.work" } },
	gomod = { name = { "go.mod", "go.sum", "go.work" } },
	gowork = { name = { "go.work" } },

	lua = { ext = { "lua" } },

	python = {
		ext = { "py", "pyi" },
		name = { "pyproject.toml", "requirements.txt", "setup.cfg", "setup.py" },
	},

	javascript = {
		ext = { "js", "jsx", "mjs", "cjs" },
		name = { "package.json", "package-lock.json", "pnpm-lock.yaml", "yarn.lock", "jsconfig.json" },
	},
	typescript = {
		ext = { "ts", "tsx", "mts", "cts" },
		name = {
			"package.json",
			"package-lock.json",
			"pnpm-lock.yaml",
			"yarn.lock",
			"tsconfig.json",
			"tsconfig.base.json",
		},
	},
	json = { ext = { "json", "jsonc" } },

	rust = {
		ext = { "rs" },
		name = { "Cargo.toml", "Cargo.lock", "rust-toolchain", "rust-toolchain.toml" },
	},

	c = { ext = { "c", "h" } },
	cpp = { ext = { "cc", "cpp", "cxx", "h", "hh", "hpp", "hxx" } },

	sh = { ext = { "sh", "bash" } },
	zsh = { ext = { "zsh" } },

	terraform = { ext = { "tf", "tfvars" } },
	yaml = { ext = { "yml", "yaml" } },
	toml = { ext = { "toml" } },
}

local function set_add(set, items)
	if not items then
		return
	end
	for _, v in ipairs(items) do
		set[v] = true
	end
end

local function merge_allow(dst, src)
	for k, _ in pairs(src.ext) do
		dst.ext[k] = true
	end
	for k, _ in pairs(src.name) do
		dst.name[k] = true
	end
end

local function is_ignored_dirname(name, ignored_extra)
	if DEFAULT_IGNORED_DIRS[name] then
		return true
	end
	if ignored_extra and ignored_extra[name] then
		return true
	end
	-- Ignore dot-directories by default
	if name:match("^%.") then
		return true
	end
	return false
end

local function should_track_path(path, allow)
	local base = vim.fs.basename(path)
	if allow.name[base] then
		return true
	end
	local ext = path:match("%.([%w_]+)$")
	if ext and allow.ext[ext] then
		return true
	end
	return false
end

local function client_supports_watched_files(client)
	if client and client.supports_method then
		return client:supports_method("workspace/didChangeWatchedFiles")
	end
	return false
end

local function warn_once_watch_fail(st, msg)
	if st.warned_watch_fail then
		return
	end
	st.warned_watch_fail = true
	vim.notify(msg, vim.log.levels.WARN)
end

local function warn_no_map_once(st, client)
	local name = client.name or ("client#" .. tostring(client.id))
	st.warned_no_map[name] = st.warned_no_map[name] or false
	if st.warned_no_map[name] then
		return
	end
	st.warned_no_map[name] = true

	local fts = (client.config and client.config.filetypes) or {}
	local ft_str = (#fts > 0) and table.concat(fts, ", ") or "(none)"

	vim.notify(
		(
			"[lsp-external-watch] No FT_MAP entry for %s (filetypes: %s). "
			.. "External-change notifications will be disabled for files not covered by FT_MAP. "
			.. "Add an entry to FT_MAP if you need it."
		):format(name, ft_str),
		vim.log.levels.WARN
	)
end

local function compute_allow_for_client(st, client)
	local allow = { ext = {}, name = {} }

	local fts = (client.config and client.config.filetypes) or {}
	for _, ft in ipairs(fts) do
		local spec = FT_MAP[ft]
		if spec then
			set_add(allow.ext, spec.ext)
			set_add(allow.name, spec.name)
		end
	end

	if vim.tbl_isempty(allow.ext) and vim.tbl_isempty(allow.name) then
		warn_no_map_once(st, client)
	end

	return allow
end

local function notify_clients(st, changes)
	for client_id, _ in pairs(st.clients) do
		local client = vim.lsp.get_client_by_id(client_id)
		if client and client_supports_watched_files(client) then
			client:notify("workspace/didChangeWatchedFiles", { changes = changes })
		end
	end
end

local function ensure_timer(st, debounce_ms)
	if st.timer then
		return
	end

	st.debounce_ms = debounce_ms
	st.timer = uv.new_timer()

	st.flush = vim.schedule_wrap(function()
		local pending = st.pending
		st.pending = {}

		if vim.tbl_isempty(pending) then
			return
		end

		local changes = {}
		for path, _ in pairs(pending) do
			local stat = uv.fs_stat(path)
			-- LSP change type: 1=Created, 2=Changed, 3=Deleted
			-- We don't maintain historical state; treat present as Changed, missing as Deleted.
			local typ = stat and 2 or 3
			changes[#changes + 1] = { uri = vim.uri_from_fname(path), type = typ }
		end

		if #changes > 0 then
			vim.cmd("checktime")
			notify_clients(st, changes)
		end
	end)
end

local function queue_change(st, path)
	st.pending[path] = true
	st.timer:stop()
	st.timer:start(st.debounce_ms, 0, st.flush)
end

local function watch_dir(st, dir, ignored_extra)
	if st.watchers[dir] then
		return
	end

	local h = uv.new_fs_event()
	if not h then
		warn_once_watch_fail(
			st,
			"[lsp-external-watch] Failed to create fs_event handle (uv.new_fs_event returned nil)."
		)
		return
	end

	local ok, err = pcall(function()
		h:start(dir, { recursive = false }, function(cb_err, filename, _)
			if cb_err or not filename then
				return
			end

			-- filename is relative to dir
			if is_ignored_dirname(filename, ignored_extra) then
				return
			end

			local full = vim.fs.joinpath(dir, filename)

			-- If a new directory appears, start watching it (and its subdirs).
			local st_fs = uv.fs_stat(full)
			if st_fs and st_fs.type == "directory" then
				local base = vim.fs.basename(full)
				if not is_ignored_dirname(base, ignored_extra) then
					M._walk_and_watch(st, full, ignored_extra)
				end
				return
			end

			if should_track_path(full, st.allow) then
				queue_change(st, full)
			end
		end)
	end)

	if not ok then
		warn_once_watch_fail(
			st,
			(
				"[lsp-external-watch] Failed to start watcher for %s.\nError: %s\n\n"
				.. "This often means you hit inotify watch limits. Consider increasing:\n"
				.. "  fs.inotify.max_user_watches\n"
				.. "  fs.inotify.max_user_instances\n\n"
				.. "Example (temporary): sudo sysctl -w fs.inotify.max_user_watches=524288\n"
			):format(dir, tostring(err))
		)
		pcall(function()
			h:close()
		end)
		return
	end

	st.watchers[dir] = h
end

function M._walk_and_watch(st, dir, ignored_extra)
	watch_dir(st, dir, ignored_extra)

	local scandir = uv.fs_scandir(dir)
	if not scandir then
		return
	end

	while true do
		local name, typ = uv.fs_scandir_next(scandir)
		if not name then
			break
		end
		if typ == "directory" and not is_ignored_dirname(name, ignored_extra) then
			M._walk_and_watch(st, vim.fs.joinpath(dir, name), ignored_extra)
		end
	end
end

local function stop_root(root_dir)
	local st = roots[root_dir]
	if not st then
		return
	end

	for _, h in pairs(st.watchers) do
		pcall(h.stop, h)
		pcall(h.close, h)
	end

	if st.timer then
		st.timer:stop()
		st.timer:close()
	end

	roots[root_dir] = nil
end

function M.setup(opts)
	opts = opts or {}

	if vim.fn.has("linux") ~= 1 then
		return
	end

	local debounce_ms = opts.debounce_ms or 200
	local ignored_extra = opts.ignored_dirs or {} -- map: dirname -> true

	local group = vim.api.nvim_create_augroup("LspExternalWatchLinux", { clear = true })

	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client then
				return
			end

			local root_dir = client.config and client.config.root_dir
			if not root_dir or root_dir == "" then
				return
			end

			local st = roots[root_dir]
			if not st then
				st = {
					watchers = {},
					clients = {},
					allow = { ext = {}, name = {} },
					pending = {},
					warned_watch_fail = false,
					warned_no_map = {},
				}
				roots[root_dir] = st

				ensure_timer(st, debounce_ms)

				-- Seed allow-list from the first client and start watchers for the workspace
				merge_allow(st.allow, compute_allow_for_client(st, client))
				M._walk_and_watch(st, root_dir, ignored_extra)
			else
				-- Merge allow-list for additional clients that attach in the same root
				merge_allow(st.allow, compute_allow_for_client(st, client))
			end

			st.clients[client.id] = true
		end,
	})

	vim.api.nvim_create_autocmd("LspDetach", {
		group = group,
		callback = function(ev)
			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if not client then
				return
			end

			local root_dir = client.config and client.config.root_dir
			if not root_dir or root_dir == "" then
				return
			end

			local st = roots[root_dir]
			if not st then
				return
			end

			st.clients[client.id] = nil
			if vim.tbl_isempty(st.clients) then
				stop_root(root_dir)
			end
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			for root_dir, _ in pairs(roots) do
				stop_root(root_dir)
			end
		end,
	})
end

return M
