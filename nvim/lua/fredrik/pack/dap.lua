local dap = require("dap")
local ui = require("dapui")

require("dapui").setup()
require("dap-go").setup()

---@diagnostic disable-next-line: missing-parameter
require("nvim-dap-virtual-text").setup()

require("dap-bazel-go").setup({})

vim.fn.sign_define("DapBreakpoint", { text = "🛑", texthl = "DiagnosticSignError", linehl = "", numhl = "" })

vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint)
vim.keymap.set("n", "<leader>dr", dap.run_to_cursor)
vim.keymap.set("n", "<leader>dc", ui.close)
vim.keymap.set("n", "<leader>do", ui.open)
vim.keymap.set("n", "<leader>dC", dap.clear_breakpoints)

vim.keymap.set("n", "<space>?", function()
	---@diagnostic disable-next-line: missing-fields
	require("dapui").eval(nil, { enter = true })
end)

vim.keymap.set("n", "<F1>", dap.continue)
vim.keymap.set("n", "<F2>", dap.step_into)
vim.keymap.set("n", "<F3>", dap.step_over)
vim.keymap.set("n", "<F4>", dap.step_out)
vim.keymap.set("n", "<F5>", dap.step_back)
vim.keymap.set("n", "<F6>", dap.restart)

dap.listeners.before.attach.dapui_config = function()
	ui.open()
end
dap.listeners.before.launch.dapui_config = function()
	ui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
	ui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
	ui.close()
end

-- Bazel Go keymaps
local dbgo = require("dap-bazel-go")
vim.keymap.set("n", "<leader>dt", dbgo.debug_test_at_cursor, { desc = "Debug test at cursor" })
vim.keymap.set("n", "<leader>df", dbgo.debug_file_test, { desc = "Debug file test" })
vim.keymap.set("n", "<leader>dl", dbgo.debug_last_test, { desc = "Re-run last test" })
vim.keymap.set("n", "<leader>dB", dbgo.set_function_breakpoint, { desc = "Set function breakpoint" })
