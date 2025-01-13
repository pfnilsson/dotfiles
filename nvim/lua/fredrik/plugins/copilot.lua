return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = {
                enabled = true,
                auto_trigger = true,
                debounce = 75,
                keymap = {
                    accept = "<C-J>",
                    accept_word = false,
                    accept_line = false,
                    next = "<C-N>",
                    prev = "<C-P>",
                    dismiss = "<C-E>",
                },
            },
            filetypes = {
                help = false,
            },
            copilot_node_command = 'node', -- Ensure Node.js version is > 16.x
            server_opts_overrides = {},
        })
    end,
}
