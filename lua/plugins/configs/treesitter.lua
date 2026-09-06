local parsers = {
	-- languages
	"bash",
	"c",
	"clojure",
	"fennel",
	"go",
	"gomod",
	"gosum",
	"groovy",
	"java",
	"javadoc",
	"javascript",
	"kotlin",
	"lua",
	"luadoc",
	"make",
	"proto",
	"python",
	"rust",
	"scheme",
	"sql",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	-- markup
	"css",
	"html",
	"markdown",
	"markdown_inline",
	"xml",
	"asm",
	-- config
	"dot",
	"toml",
	"yaml",
	-- data
	"csv",
	"json",
	"json5",
	-- utility
	"diff",
	"disassembly",
	"dockerfile",
	"git_config",
	"git_rebase",
	"gitcommit",
	"gitignore",
	"http",
	"mermaid",
	"printf",
	"query",
	"ssh_config",
}

vim.treesitter.language.register("javascript", "tsx")
vim.treesitter.language.register("typescript.tsc", "tsx")

vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})

return parsers
