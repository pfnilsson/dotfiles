local function diff_source()
	local gitsigns = vim.b.gitsigns_status_dict
	if gitsigns then
		return {
			added = gitsigns.added,
			modified = gitsigns.changed,
			removed = gitsigns.removed,
		}
	end
end

local gpd = require("fredrik.gpd_status")
gpd.setup()

require("lualine").setup({
	options = {
		theme = "auto",
		globalstatus = true,
		section_separators = "",
		component_separators = "",
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", { "diff", source = diff_source }, "diagnostics" },
		lualine_c = {
			{
				"filename",
				path = 1,
				shorting_target = 40,
				symbols = {
					modified = "●",
					readonly = "🔒",
					unnamed = "📄",
				},
			},
		},
		lualine_x = { gpd.lualine_component(), "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
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
