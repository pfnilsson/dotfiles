require("sidekick").setup({
	nes = { enabled = false },
	cli = {
		win = {
			layout = "float",
			float = {
				width = 1.0,
				height = 1.0,
			},
		},
		mux = {
			backend = "tmux",
			enabled = false,
		},
	},
})

vim.keymap.set({ "x", "n" }, "<leader>at", function()
	require("sidekick.cli").send({ name = "claude", msg = "{this}" })
end, { desc = "Send This" })

vim.keymap.set("n", "<leader>af", function()
	require("sidekick.cli").send({ name = "claude", msg = "{file}" })
end, { desc = "Send File" })

vim.keymap.set("x", "<leader>av", function()
	require("sidekick.cli").send({ name = "claude", msg = "{selection}" })
end, { desc = "Send Visual Selection" })

vim.keymap.set({ "n", "t", "i", "x" }, "<F24>", function()
	require("sidekick.cli").toggle({ name = "claude", focus = true })
end, { desc = "Sidekick Toggle Claude" })

vim.keymap.set({ "n", "t", "i", "x" }, "<S-F12>", function()
	require("sidekick.cli").toggle({ name = "claude", focus = true })
end, { desc = "Sidekick Toggle Claude" })
