local M = {}

function M.init()
	local ok_blink, blink_cmp = pcall(require, "blink.cmp")
	local capabilities = (ok_blink and blink_cmp.get_lsp_capabilities()) or vim.lsp.protocol.make_client_capabilities()
	local item = capabilities.textDocument
		and capabilities.textDocument.completion
		and capabilities.textDocument.completion.completionItem
	if item then
		item.snippetSupport = false
	end

	return { capabilities = capabilities }
end

return M
