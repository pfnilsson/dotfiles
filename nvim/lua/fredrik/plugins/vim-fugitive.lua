return {
    "tpope/vim-fugitive",
    dependencies = { "tpope/vim-rhubarb" },
    config = function()
        vim.keymap.set({ "n", "v" }, "<leader>gx", ":GBrowse<CR>", { desc = "Open GitHub in browser" })
        vim.keymap.set("n", "<leader>gB", ":G blame<CR>", { desc = "Git blame" })
    end,
}
