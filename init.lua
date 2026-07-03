require("core")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	require("core.bootstrap").lazy(lazypath)
end

vim.opt.rtp:prepend(lazypath)
require("plugins")
require("snippets")
require("mdpreview")

vim.api.nvim_create_user_command("ObscuraSync", function()
	require("core.bootstrap").sync()
end, { desc = "Install all plugins, mason tools and treesitter parsers" })

if not pcall(vim.cmd.colorscheme, "koda-dark") then
	vim.notify("colorscheme koda is not installed yet, run :ObscuraSync", vim.log.levels.WARN)
end
