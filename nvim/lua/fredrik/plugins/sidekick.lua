return {
	"folke/sidekick.nvim",
	opts = {
		cli = {
			mux = {
				backend = "tmux",
				enabled = false,
			},
		},
	},
	keys = {
		{
			"<Tab>",
			function()
				local Nes = require("sidekick.nes")
				if not (Nes.have() and (Nes.apply() or Nes.jump())) then
					return "<Tab>"
				end
			end,
			expr = true,
			mode = { "n" },
			desc = "Apply-or-Jump NES",
		},
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
				require("sidekick.cli").send({ msg = "{this}" })
			end,
			mode = { "x", "n" },
			desc = "Send This",
		},
		{
			"<leader>af",
			function()
				require("sidekick.cli").send({ msg = "{file}" })
			end,
			desc = "Send File",
		},
		{
			"<leader>av",
			function()
				require("sidekick.cli").send({ msg = "{selection}" })
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
