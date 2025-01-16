return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = {
                auto_trigger = false,
                keymap = {
                    accept = "<C-j>",
                    next = "<C-n>",
                    prev = "<C-p>"
                }
            }
        })
    end
}
