require("core")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	require("core.bootstrap").lazy(lazypath)
end

vim.opt.rtp:prepend(lazypath)
require("plugins")
require("snippets")
require("mdpreview")

vim.cmd.colorscheme("moss")
