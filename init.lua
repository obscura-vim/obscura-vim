require("core")
require("plugins")
require("snippets")

if not pcall(vim.cmd.colorscheme, "koda-" .. vim.o.background) then
	vim.notify("koda is not installed yet; restart Neovim after vim.pack installs packages", vim.log.levels.WARN)
end
