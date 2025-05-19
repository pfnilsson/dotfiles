return {
    {
        "folke/snacks.nvim",
        init = function()
            vim.defer_fn(function()
                local result = vim.fn.systemlist('git rev-parse --is-inside-work-tree 2> /dev/null')
                _G.git_cache = (result[1] == 'true')
            end, 0)
        end,
        keys = {
            { "<leader>gx", function() Snacks.gitbrowse.open() end, mode = { "n", "v" } },
            { "<leader>lg", function() Snacks.lazygit.open() end },
            {
                "<leader>gl",
                function()
                    Snacks.picker.git_log({
                        finder = "git_log",
                        format = "git_log",
                        preview = "git_show",
                        confirm = "git_checkout",
                        layout = "vertical",
                    })
                end,
                desc = "Git Log",
            },
            { "<leader>gb", function() Snacks.picker.git_branches({ layout = "select", }) end, desc = "Branches", },
            { "<leader>gs", function() Snacks.picker.git_status() end,                         desc = "Git Status" },
            { "<leader>km", function() Snacks.picker.keymaps({ layout = "vertical", }) end,    desc = "Keymaps", },
            {
                "<leader>ff",
                function()
                    if _G.git_cache == true then
                        Snacks.picker.git_files()
                    else
                        Snacks.picker.files({
                            finder = "files",
                            format = "file",
                            show_empty = true,
                            supports_live = true,
                        })
                    end
                end,
                desc = "Find Files (Git Preferred)"
            },
            { "<leader>fF",
                function()
                    Snacks.picker.files({
                        finder = "files",
                        format = "file",
                        show_empty = true,
                        supports_live = true,
                    })
                end, },
            desc = "Find Files (All)",
            { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
            {
                "<leader>fg",
                function()
                    if _G.git_cache == true then
                        Snacks.picker.grep(
                            {
                                finder = "git_grep",
                                format = "file",
                                untracked = true,
                                need_search = true,
                                show_empty = true,
                                supports_live = true,
                                live = true,
                            }
                        )
                    else
                        Snacks.picker.grep()
                    end
                end,
                desc = "Grep (Git Preferred)"
            },
            { "<leader>fG", function() Snacks.picker.grep() end,     desc = "Grep (All)" },
            {
                "<leader>b",
                function()
                    Snacks.picker.buffers({
                        finder = "buffers",
                        format = "buffer",
                        hidden = false,
                        unloaded = true,
                        current = true,
                        sort_lastused = true,
                        -- Fiter out notes and unnamed buffers
                        filter = {
                            filter = function(item)
                                local name = item.file:match("([^/\\]+)$")

                                if name:match("^%[No Name") then
                                    return false
                                end

                                if name:match("^%d%d_.*%.txt$") then
                                    return false
                                end

                                return true
                            end,
                        },
                        win = {
                            input = { keys = { ["<C-d>"] = { "bufdelete", mode = { "n", "i" } }, }, },
                            list = { keys = { ["<C-d>"] = { "bufdelete", mode = { "n", "i" } } } },
                        },
                        layout = "default",
                    })
                end,
                desc = "Snacks picker buffers",
            },
            { "<leader>lD", function() Snacks.picker.diagnostics() end,          desc = "Diagnostics" },
            { "<leader>ld", function() Snacks.picker.diagnostics_buffer() end,   desc = "Buffer Diagnostics" },
            { "gd",         function() Snacks.picker.lsp_definitions() end,      desc = "Goto Definition" },
            { "gD",         function() Snacks.picker.lsp_declarations() end,     desc = "Goto Declaration" },
            { "gr",         function() Snacks.picker.lsp_references() end,       nowait = true,                desc = "References" },
            { "gi",         function() Snacks.picker.lsp_implementations() end,  desc = "Goto Implementation" },
            { "gt",         function() Snacks.picker.lsp_type_definitions() end, desc = "Goto Type Definition" },
            {
                "<leader>E",
                function()
                    Snacks.picker.explorer({
                        finder = "explorer",
                        sort = { fields = { "sort" } },
                        supports_live = true,
                        tree = true,
                        watch = true,
                        diagnostics = true,
                        diagnostics_open = false,
                        git_status = true,
                        git_status_open = false,
                        git_untracked = true,
                        follow_file = true,
                        focus = "list",
                        auto_close = true,
                        jump = { close = true },
                        layout = { preset = "sidebar", preview = false, layout = { width = 0.4 } },
                        formatters = {
                            file = { filename_only = true },
                            severity = { pos = "right" },
                        },
                        matcher = { sort_empty = false, fuzzy = false },
                        config = function(opts)
                            return require("snacks.picker.source.explorer").setup(opts)
                        end,
                        win = {
                            list = {
                                keys = {
                                    ["<BS>"] = "explorer_up",
                                    ["l"] = "confirm",
                                    ["h"] = "explorer_close", -- close directory
                                    ["a"] = "explorer_add",
                                    ["d"] = "explorer_del",
                                    ["r"] = "explorer_rename",
                                    ["c"] = "explorer_copy",
                                    ["m"] = "explorer_move",
                                    ["o"] = "explorer_open", -- open with system application
                                    ["P"] = "toggle_preview",
                                    ["y"] = { "explorer_yank", mode = { "n", "x" } },
                                    ["p"] = "explorer_paste",
                                    ["u"] = "explorer_update",
                                    ["<c-c>"] = "tcd",
                                    ["<leader>/"] = "picker_grep",
                                    ["<c-t>"] = "terminal",
                                    ["."] = "explorer_focus",
                                    ["I"] = "toggle_ignored",
                                    ["H"] = "toggle_hidden",
                                    ["Z"] = "explorer_close_all",
                                    ["]g"] = "explorer_git_next",
                                    ["[g"] = "explorer_git_prev",
                                    ["]d"] = "explorer_diagnostic_next",
                                    ["[d"] = "explorer_diagnostic_prev",
                                    ["]w"] = "explorer_warn_next",
                                    ["[w"] = "explorer_warn_prev",
                                    ["]e"] = "explorer_error_next",
                                    ["[e"] = "explorer_error_prev",
                                },
                            },
                        },
                    })
                end,
                desc = "File Explorer"
            }
        },
        opts = {
            gitbrowse = {
                open = function(url)
                    local mode = vim.fn.mode()

                    if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
                        -- Remove patterns for GitHub/GitLab style anchors: "#L<start>-L<end>"
                        url = url:gsub("#L%d+%-L%d+", "")
                        -- Remove Bitbucket style anchors: "#lines-<start>-L<end>"
                        url = url:gsub("#lines%-%d+%-L%d+", "")
                        -- Remove git.sr.ht style anchors: "#L<start>"
                        url = url:gsub("#L%d+", "")
                    end

                    vim.ui.open(url)
                end
            },

            lazygit = {},
            explorer = {},
            picker = {
                ui_select = true,
                layout = { preset = "default" },
                layouts = {
                    vertical = {
                        layout = {
                            backdrop = false,
                            width = 0.8,
                            min_width = 80,
                            height = 0.8,
                            min_height = 30,
                            box = "vertical",
                            border = "rounded",
                            title = "{title} {live} {flags}",
                            title_pos = "center",
                            { win = "input",   height = 1,          border = "bottom" },
                            { win = "list",    border = "none" },
                            { win = "preview", title = "{preview}", height = 0.4,     border = "top" },
                        },
                    },
                },
                matcher = {
                    frecency = true,
                },
                win = {
                    input = {
                        keys = {
                            ["<Esc>"] = { "close", mode = { "n", "i" } },
                            ["J"] = { "preview_scroll_down", mode = { "n" } },
                            ["K"] = { "preview_scroll_up", mode = { "n" } },
                            ["H"] = { "preview_scroll_left", mode = { "n" } },
                            ["L"] = { "preview_scroll_right", mode = { "n" } },
                            ["<C-c>"] = { function() vim.cmd.stopinsert() end, mode = { "i", "n" } }
                        },
                    },
                },
                formatters = {
                    file = {
                        filename_first = true, -- display filename before the file path
                        truncate = 80,
                    },
                },
                sources = {
                    explorer = {
                        win = {
                            list = {
                                wo = {
                                    number = true,
                                    relativenumber = true
                                }
                            }

                        }
                    }
                }
            },
        },
    },
}
