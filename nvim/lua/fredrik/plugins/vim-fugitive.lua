return {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    config = function()
        local function toggle_git_fugitive()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_get_option(buf, 'filetype') == 'fugitive' then
                    vim.api.nvim_win_close(win, true)
                    return
                end
            end
            vim.cmd.Git()
        end

        vim.keymap.set("n", "gh", "<cmd>diffget //2<CR>", { desc = "Choose left version" })
        vim.keymap.set("n", "gl", "<cmd>diffget //3<CR>", { desc = "Choose right version" })
        vim.keymap.set("n", "<leader>G", toggle_git_fugitive, { desc = "Toggle Fugitive" })
        vim.keymap.set({ "n", "v" }, "<leader>gw", ":GBrowse<CR>", { desc = "Open GitHub in browser" })
        vim.keymap.set("n", "<leader>gB", ":G blame<CR>", { desc = "Git blame" })
    end
}
