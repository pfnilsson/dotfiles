return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("lualine").setup({
            options = {
                theme = "auto",
                section_separators = "",
                component_separators = "",
            },
            sections = {
                -- Define the left side of the statusline
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },

                -- Center section with filename and its relative path
                lualine_c = {
                    {
                        "filename",
                        path = 1, -- 0: Just the filename
                        -- 1: Relative path from the current working directory
                        -- 2: Absolute path
                        shorting_target = 40, -- Shortens the path if it exceeds 40 characters
                        symbols = {
                            modified = "●", -- Symbol to indicate modified file
                            readonly = "🔒", -- Symbol to indicate readonly file
                            unnamed = "📄", -- Symbol for unnamed buffer
                        },
                    },
                },

                -- Right side of the statusline
                lualine_x = { "encoding", "fileformat", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
            inactive_sections = {
                -- Sections for inactive windows
                lualine_a = {},
                lualine_b = {},
                lualine_c = { "filename" },
                lualine_x = { "location" },
                lualine_y = {},
                lualine_z = {},
            },
            tabline = {},
            extensions = {},
        })
    end,
}
