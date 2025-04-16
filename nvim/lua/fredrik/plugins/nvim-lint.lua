return {
    "mfussenegger/nvim-lint",
    config = function()
        local lint = require("lint")

        lint.linters_by_ft = {
            go = { "golangcilint" },
        }
        lint.linters.golangcilint = {
            cmd = "golangci-lint",
            args = { "run" },
            name = "golangcilint",
            stdin = false,
            stream = "stdout",
            parser = require("lint.parser").from_errorformat("%f:%l:%c: %m", { severity = vim.diagnostic.severity.WARN }),
            ignore_exitcode = true,
        }
        -- Create an autocommand to run linting on write, leaving insert mode and entering a buffer for Go files
        vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufEnter" }, {
            pattern = { "*.go" },
            callback = function()
                require("lint").try_lint()
            end,
        })
    end,
}
