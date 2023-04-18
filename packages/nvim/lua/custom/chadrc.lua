local M = {}

M.ui = {
	theme = "doomchad",
	transparency = false,
}

M.plugins = {
	user = {
		-- Enable Dashboard
		["goolord/alpha-nvim"] = {
			disable = false,
		},

		-- Hop
		["phaazon/hop.nvim"] = {
			branch = "v2",
			config = function()
				require("hop").setup { keys = "etovxqpdygfblzhckisuran" }
			end
		},

		-- Undo tree
		["mbbill/undotree"] = {},
	}
}

return M
