local M = {}

function M.init()
	local base = vim.lsp.protocol.make_client_capabilities()

	local ok_blink, blink_cmp = pcall(require, "blink.cmp")
	local blink_caps = ok_blink and blink_cmp.get_lsp_capabilities() or {}

	local capabilities = vim.tbl_deep_extend("force", base, blink_caps)

	local item = capabilities.textDocument
		and capabilities.textDocument.completion
		and capabilities.textDocument.completion.completionItem

	if item then
		item.snippetSupport = false
	end

	return { capabilities = capabilities }
end

return M
