return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local builtin = require("telescope.builtin")
        local nvim_tree_api = require("nvim-tree.api")

        -- cache whether we are in a git repo or not
        local git_cache = nil

        -- Run asynchronously on startup
        vim.defer_fn(function()
            local result = vim.fn.systemlist('git rev-parse --is-inside-work-tree 2> /dev/null')
            git_cache = result[1] == 'true'
        end, 0)

        local function close_all_git_clean_buffers()
            -- Get the list of files with uncommitted changes as full paths
            local git_status_output = vim.fn.system("git status -s | awk '{print $2}' | xargs realpath")
            local modified_files = {}

            -- Parse the output into a table of modified file paths
            for line in git_status_output:gmatch("[^\r\n]+") do
                modified_files[line] = true
            end

            -- Iterate over all buffers
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
                    local filepath = vim.api.nvim_buf_get_name(bufnr)
                    -- Check if the buffer's file is not in the modified files list
                    if not modified_files[filepath] then
                        vim.cmd("bdelete! " .. bufnr)
                    end
                end
            end
        end


        local function close_git_clean_buffers_and_reload()
            local picker = action_state.get_current_picker(vim.api.nvim_get_current_buf())
            if picker then
                local prompt_bufnr = picker.prompt_bufnr

                -- 1) Close all unchanged buffers
                close_all_git_clean_buffers()

                -- 2) Close the current Telescope window
                actions.close(prompt_bufnr)

                -- 3) Immediately re-open the buffers picker
                builtin.buffers({
                    sort_mru = true,
                    sort_lastused = true,
                    initial_mode = "normal",
                })
            else
                close_all_git_clean_buffers()
            end

            vim.notify("Closed all unchanged buffers", vim.log.levels.INFO)
        end

        local function select_and_close_nvim_tree(prompt_bufnr)
            actions.select_default(prompt_bufnr)
            nvim_tree_api.tree.close()
        end

        telescope.setup({
            defaults = {
                mappings = {
                    n = {
                        ["d"] = actions.delete_buffer,
                        ["q"] = actions.close,
                        ["<CR>"] = select_and_close_nvim_tree,
                    },
                    i = {
                        ["<CR>"] = select_and_close_nvim_tree,
                        ["<esc>"] = actions.close,
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<Up>"] = function() end,
                        ["<Down>"] = function() end
                    }
                },
            },
            pickers = {
                buffers = {
                    mappings = {
                        n = {
                            ["u"] = close_git_clean_buffers_and_reload,
                        },
                    },
                },
            },
        })

        local function find_files_or_git_files()
            if git_cache == true then
                builtin.git_files()
            else
                builtin.find_files()
            end
        end

        local function live_grep_git_or_all()
            if git_cache == true then
                -- Inside a Git repository: Search only Git-tracked files
                builtin.live_grep({
                    -- Use git's built-in file listing with '--iglob' to limit search scope
                    -- Alternatively, you can modify 'vimgrep_arguments' to better suit your needs
                    -- Here, we ensure that ripgrep respects .gitignore
                    vimgrep_arguments = {
                        'rg',
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                    },
                    -- Set 'search_dirs' to the Git root to ensure consistent searching
                    cwd = vim.fn.systemlist('git rev-parse --show-toplevel')[1],
                })
            else
                -- Not inside a Git repository: Search all files
                builtin.live_grep({
                    -- Modify 'vimgrep_arguments' to include hidden files and ignore ignore files
                    vimgrep_arguments = {
                        'rg',
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                        '--hidden',    -- Include hidden files
                        '--no-ignore', -- Do not respect ignore files
                    },
                })
            end
        end
        vim.keymap.set("n", "<leader>ff", find_files_or_git_files, { desc = "Find Files (Git preferred)" })
        vim.keymap.set("n", "<leader>fg", live_grep_git_or_all, { desc = "Live Grep (Git preferred)" })
        vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git Status" })
        vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = "Git Branches" })
        vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = "Git Branches" })
        vim.keymap.set("n", "<leader>fF", builtin.find_files, { desc = "Find Files (All)" })
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help Tags" })
        vim.keymap.set('n', '<leader>fG', builtin.live_grep, { desc = "Live Grep (All)" })
        vim.keymap.set("n", "<leader>ld", function() builtin.diagnostics({ bufnr = 0 }) end,
            { desc = "List diagnostics in current buffer" })
        vim.keymap.set("n", "<leader>lD", builtin.diagnostics, { desc = "List all diagnostics" })
    end
}
