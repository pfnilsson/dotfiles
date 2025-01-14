return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    dependencies = {
        "zbirenbaum/copilot-cmp", -- Ensure copilot-cmp is a dependency
    },
    config = function()
        require("copilot").setup({
            suggestion = {
                enabled = false,      -- Disable built-in suggestions
                auto_trigger = false, -- Disable auto-trigger to use copilot-cmp
                debounce = 75,
            },
            filetypes = {
                help = false,
            },
            copilot_node_command = 'node', -- Ensure Node.js version is > 16.x
            server_opts_overrides = {},
        })
    end,
}
