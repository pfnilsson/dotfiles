return {
    {
        "VanyaDNDZ/nvim-dap-bazel-go",
        config = function()
            require("dap-bazel-go").setup({})
            -- Optionally define key mappings:
            local dbgo = require("dap-bazel-go")
            vim.keymap.set("n", "<leader>dt", dbgo.debug_test_at_cursor, { desc = "Debug test at cursor" })
            vim.keymap.set("n", "<leader>df", dbgo.debug_file_test, { desc = "Debug file test" })
            vim.keymap.set("n", "<leader>dl", dbgo.debug_last_test, { desc = "Re-run last test" })
            vim.keymap.set("n", "<leader>dB", dbgo.set_function_breakpoint, { desc = "Set function breakpoint" })
        end,
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-treesitter/nvim-treesitter",
        },
    },
}
