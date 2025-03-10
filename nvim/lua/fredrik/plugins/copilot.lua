return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = {
                auto_trigger = false,
                keymap = {
                    accept = "<C-y>",
                    next = "<C-n>",
                    prev = "<C-p>"
                }
            }
        })
    end
}
