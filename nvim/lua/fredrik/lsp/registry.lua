local M = {}

M.servers = {
	"lua_ls",
	"ty",
	"gopls",
	"html",
	"jsonls",
	"rust_analyzer",
	"sqls",
	"terraformls",
	"ruff",
	"zls",
}

M.tools = {
	"prettier",
	"stylua",
	"pylint",
	"eslint_d",
	"delve",
	"copilot-language-server",
}

function M.partition()
	local custom, defaults = {}, {}
	for _, name in ipairs(M.servers) do
		local mod = "fredrik.lsp." .. name
		local ok = package.loaded[mod] ~= nil or (function()
			local ok2 = pcall(require, mod)
			return ok2
		end)()
		if ok then
			table.insert(custom, mod)
		else
			table.insert(defaults, name)
		end
	end
	return custom, defaults
end

return M
