local map = require("core.mappings")

vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "4916d659" },
	{ src = "https://github.com/iamcco/markdown-preview.nvim", version = "a923f5f" },
	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim", version = "d28a3f7" },
	{ src = "https://github.com/williamboman/mason.nvim", version = "2a6940a" },
	{ src = "https://github.com/saghen/blink.cmp", version = "78336bc" },
	{ src = "https://github.com/nvim-lua/plenary.nvim", version = "74b06c6" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim", version = "427b576" },
	{ src = "https://github.com/akinsho/git-conflict.nvim", version = "4bbfdd9" },
	{ src = "https://github.com/lervag/vimtex", version = "5e6a06f5" },
	{ src = "https://github.com/stevearc/conform.nvim", version = "619363c" },
	{ src = "https://github.com/kevinhwang91/promise-async", version = "119e896" },
	{ src = "https://github.com/kevinhwang91/nvim-ufo", version = "ab3eb12" },
	{ src = "https://github.com/oskarnurm/koda.nvim", version = "a7da3ce" },
	{ src = "https://github.com/norcalli/nvim-colorizer.lua", version = "a065833" },
	{ src = "https://github.com/folke/flash.nvim", version = "fcea7ff" },
	{ src = "https://github.com/reedes/vim-pencil", version = "6d70438" },
	{ src = "https://github.com/nativerv/cyrillic.nvim", version = "86186af" },
	{ src = "https://github.com/saghen/blink.lib", version = "5876dd9" },
	{ src = "https://github.com/saghen/blink.pairs", version = "aad9046" },
})

require("plugins.configs.treesitter")

require("ibl").setup({
	indent = { char = "▏" },
	enabled = false,
	scope = { enabled = false, show_start = false, show_end = false, highlight = nil },
})

local mason_options = require("plugins.configs.mason")
require("mason").setup(mason_options)
vim.g.mason_binaries_list = mason_options.ensure_installed

vim.keymap.set({ "i", "s" }, "<Tab>", function()
	if vim.snippet.active({ direction = 1 }) then
		vim.snippet.jump(1)
		return ""
	elseif require("snippets").expand() then
		return ""
	end
	return "<Tab>"
end, { expr = true, silent = true })

vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
	if vim.snippet.active({ direction = -1 }) then
		vim.snippet.jump(-1)
		return ""
	end
	return "<S-Tab>"
end, { expr = true, silent = true })

require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<CR>"] = { "accept", "fallback" },
		["<C-j>"] = { "select_next", "show" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-e>"] = { "hide", "fallback" },
	},
	cmdline = {
		enabled = true,
		completion = { menu = { auto_show = false }, ghost_text = { enabled = false } },
		keymap = {
			["<Tab>"] = { "show", "accept" },
			["<Esc>"] = { "cancel" },
			["<C-j>"] = { "show_and_insert_or_accept_single", "select_next" },
			["<C-k>"] = { "show_and_insert_or_accept_single", "select_prev" },
			["<CR>"] = { "accept", "fallback" },
		},
	},
	completion = {
		documentation = { auto_show = true, window = { border = "rounded" } },
		trigger = { show_on_insert = false, show_on_keyword = false, show_on_trigger_character = false },
		menu = { auto_show = false, border = "rounded", winblend = 0, scrollbar = false },
	},
	appearance = { nerd_font_variant = "mono", use_nvim_cmp_as_default = false },
	sources = { default = { "lsp", "path", "buffer" } },
	fuzzy = { implementation = "prefer_rust_with_warning" },
})

require("telescope").setup(require("plugins.configs.telescope"))
require("plugins.configs.lspconfig")
require("git-conflict").setup()
require("plugins.configs.others").vimtex()
require("plugins.configs.conform")
require("plugins.configs.others").ufo()

vim.g["pencil#wrapMode"] = "hard"
vim.g["pencil#textwidth"] = 65
vim.g["pencil#autoformat"] = 1

require("koda").setup({
	transparent = true,
	colors = { bg = vim.o.background == "light" and "#faf9f5" or "#000000" },
})

require("cyrillic").setup({ no_cyrillic_abbrev = false })

require("blink.pairs").download():pwait(60000)
require("blink.pairs").setup({
	mappings = { enabled = true, cmdline = true, disabled_filetypes = {}, pairs = {} },
	highlights = {
		enabled = true,
		cmdline = true,
		groups = { "BlinkPairs" },
		unmatched_group = "BlinkPairsUnmatched",
		matchparen = { enabled = true, cmdline = false, include_surrounding = false, group = "BlinkPairsMatchParen", priority = 250 },
	},
	debug = false,
})

vim.keymap.set("n", "s", function()
	require("flash").jump()
end, { desc = "Flash" })

vim.keymap.set("n", "<leader>i", map.ibl["<leader>i"], { desc = "Toggle indent blankline" })
vim.keymap.set("n", "zR", map.ufo.zR, { desc = "Open all folds" })
vim.keymap.set("n", "zM", map.ufo.zM, { desc = "Close all folds" })
vim.keymap.set("n", "<leader>h", map.ufo["<leader>h"], { desc = "Toggle fold under cursor" })
vim.keymap.set("n", "<leader>c", map.colorizer["<leader>c"], { desc = "Toggle Colorizer" })
vim.keymap.set("n", "<leader>g", map.gitsigns["<leader>g"], { desc = "Toggle Git signs" })
