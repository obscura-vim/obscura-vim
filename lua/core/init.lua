local opt = vim.opt
local g = vim.g

opt.laststatus = 0
opt.showmode = false

opt.clipboard = "unnamedplus"

opt.scrolloff = 5
opt.scrolljump = 2

opt.expandtab = true
opt.shiftwidth = 4
opt.smartindent = true
opt.tabstop = 4
opt.softtabstop = 4

opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

opt.number = false
opt.numberwidth = 2
opt.ruler = false

opt.shortmess:append("s")

opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 400
opt.undofile = true

opt.updatetime = 250

vim.opt.fillchars:append({ eob = "~" })
vim.opt.list = false
vim.opt.shortmess:remove("I")

local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
if not is_windows then
	vim.o.shell = "/usr/bin/zsh"
	vim.o.shellcmdflag = "-c"
end

vim.o.background = "dark"
vim.o.showtabline = 0
vim.o.cursorline = true

g.mapleader = " "

for _, provider in ipairs({ "node", "perl", "python3", "ruby" }) do
	vim.g["loaded_" .. provider .. "_provider"] = 0
end

vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH

local function in_markdown_yaml()
	if vim.bo.filetype ~= "markdown" then
		return false
	end

	local cur = vim.fn.line(".")

	if vim.fn.getline(1) ~= "---" then
		return false
	end

	for i = 2, vim.fn.line("$") do
		if vim.fn.getline(i) == "---" then
			return cur > 1 and cur < i
		end
	end

	return false
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			buffer = 0,
			callback = function()
				if in_markdown_yaml() then
					vim.bo.shiftwidth = 2
					vim.bo.tabstop = 2
					vim.bo.softtabstop = 2
					vim.bo.expandtab = true
				else
					vim.bo.shiftwidth = 4
					vim.bo.tabstop = 4
					vim.bo.softtabstop = 4
				end
			end,
		})
	end,
})
