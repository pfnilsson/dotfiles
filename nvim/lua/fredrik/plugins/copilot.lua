return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = {
                auto_trigger = false,
                keymap = {
                    accept = "<C-u>",
                    next = "<C-n>",
                    prev = "<C-p>"
                }
            },
            copilot_model = "claude-sonnet-3.7"
        })
    end
}
