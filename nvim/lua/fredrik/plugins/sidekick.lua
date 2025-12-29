return {
	"folke/sidekick.nvim",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		nes = { enabled = false },
		cli = {
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
			"<leader>ad",
			function()
				require("sidekick.cli").close()
			end,
			desc = "Detach a CLI Session",
		},
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
			"<leader>aa",
			function()
				local cli = require("sidekick.cli")
				cli.show({ name = "claude", focus = true })
				vim.schedule(function()
					cli.prompt()
				end)
			end,
			mode = { "n", "x" },
			desc = "Claude prompts",
		},
	},
}
