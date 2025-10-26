return {
	-- add solarized
	{
		"maxmx03/solarized.nvim",
		opts = {
			palette = "solarized",
			variant = "autumn",
			styles = {
				constants = { bold = true },
			},
		},
	},

	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "solarized",
		},
	},
}
