-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
return {

	base46 =  {
		theme = "bearded-arc",
		theme_toggle = { 
			"bearded-arc", -- dark theme
			"one_light" -- light theme
		},
	},

	nvdash = {
		load_on_startup = true,

		header = {
			"                                                                   ",
			"      ████ ██████           █████      ██                    ",
			"     ███████████             █████                            ",
			"     █████████ ███████████████████ ███   ███████████  ",
			"    █████████  ███    █████████████ █████ ██████████████  ",
			"   █████████ ██████████ █████████ █████ █████ ████ █████  ",
			" ███████████ ███    ███ █████████ █████ █████ ████ █████ ",
			"██████  █████████████████████ ████ █████ █████ ████ ██████",
			"",
		},

		buttons = {
			{ txt = "  Find Files", keys = "ff", cmd = "Telescope find_files" },
			{ txt = "󰈭  Find Text", keys = "fw", cmd = "Telescope live_grep" },
			{ txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
			{ txt = "  View Mappings", keys = "ch", cmd = "NvCheatsheet" },

			{ txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
			{
				txt = function()
					local stats = require("lazy").stats()
					local ms = math.floor(stats.startuptime) .. " ms"
					return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
				end,
				hl = "NvDashFooter",
				no_gap = true,
			},
			{ txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
		},
	},

	ui = {
		tabufline = {
			enabled = true,
			lazyload = true,
		},
	},
}
