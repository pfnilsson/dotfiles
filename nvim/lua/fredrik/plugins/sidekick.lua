return {
	"folke/sidekick.nvim",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
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
			tools = {
				claude = {
					cmd = vim.fn.has("mac") == 1 and { "devbox", "ai" } or { "claude" },
				},
			},
		},
	},
	keys = {
		{
			"<leader>at",
			function()
				require("sidekick.cli").send({ name = "claude", msg = "{this}" })
			end,
			mode = { "x", "n" },
			desc = "Send This",
		},
		{
			"<leader>af",
			function()
				require("sidekick.cli").send({ name = "claude", msg = "{file}" })
			end,
			desc = "Send File",
		},
		{
			"<leader>av",
			function()
				require("sidekick.cli").send({ name = "claude", msg = "{selection}" })
			end,
			mode = { "x" },
			desc = "Send Visual Selection",
		},
		{
			"<F24>",
			function()
				require("sidekick.cli").toggle({ name = "claude", focus = true })
			end,
			desc = "Sidekick Toggle Claude",
			mode = { "n", "t", "i", "x" },
		},
		{
			"<S-F12>", -- duplicate to accept F24 or S-F12 depending on what is sent by terminal
			function()
				require("sidekick.cli").toggle({ name = "claude", focus = true })
			end,
			desc = "Sidekick Toggle Claude",
			mode = { "n", "t", "i", "x" },
		},
	},
}
