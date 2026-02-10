require("core")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	require("core.bootstrap").lazy(lazypath)
end

vim.opt.rtp:prepend(lazypath)
require("plugins")


vim.g.last_theme = vim.fn.stdpath("data") .. "/last_theme.txt"

if vim.fn.filereadable(vim.g.last_theme) == 1 then
    local theme = vim.fn.readfile(vim.g.last_theme)[1]
    vim.o.background = theme
    vim.cmd("colorscheme moss")
end

require("snippets")
