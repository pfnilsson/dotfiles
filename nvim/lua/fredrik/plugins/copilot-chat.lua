return {
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            { "zbirenbaum/copilot.lua" },
            { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
            { "folke/snacks.nvim" },                        -- to make picker work
        },
        build = "make tiktoken",                            -- Only on MacOS or Linux
        opts = {
            model = "claude-3.7-sonnet-thought",
            mappings = {
                reset = {
                    insert = false,
                    normal = "<C-L>"
                },
                fix = {
                    visual = "<leader>CF"
                }
            }
        },
        keys = {
            { "<leader>cp", ":CopilotChatPrompts<CR>", mode = "v", "Copilot Prompts" }
        }
    },
}
