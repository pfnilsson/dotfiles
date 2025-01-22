return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    -- This will provide type hinting with LuaLS
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
        -- Define your formatters
        formatters_by_ft = {
            python = { "isort", "black" },
            sql = { "sleek" },
        },
        format_on_save = {
            timeout_ms = 200,
            lsp_format = "fallback"
        }
    },
}
