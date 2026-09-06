local M = {}

M.vimtex = function()
	vim.g.vimtex_quickfix_enabled = 0
	vim.g.vimtex_quickfix_mode = 0

	vim.g.vimtex_compiler_method = "latexmk"
	vim.g.vimtex_compiler_progname = "nvr"

	vim.g.vimtex_compiler_latexmk = {
		aux_dir = vim.fn.expand("$HOME/latex/aux"),
		out_dir = vim.fn.expand("$HOME/latex/out"),
		build_dir = vim.fn.expand("$HOME/.cache/latex"),
		continuous = 1,
		callback = 0,
		executable = "latexmk",
		options = {
			"-pdf",
			"-interaction=nonstopmode",
			"-file-line-error",
			"-synctex=1",
			-- "-verbose",
		},
	}

	vim.g.vimtex_compiler_callback_hooks = {}
	vim.g.vimtex_view_method = "zathura"
	vim.opt.conceallevel = 1
	vim.g.tex_conceal = "abdmg"
end

M.ufo = function()
	vim.o.foldcolumn = "0"
	vim.o.foldlevel = 99
	vim.o.foldlevelstart = 99
	vim.o.foldenable = true

	require("ufo").setup({
		provider_selector = function(_, _, _)
			return { "treesitter", "indent" }
		end,
	})
end

return M
