local ts = require("nvim-treesitter")

ts.install({
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
})

vim.treesitter.language.register("javascript", "tsx")
vim.treesitter.language.register("typescript.tsc", "tsx")
