local root = vim.env.NVIM_TEX_TEST_RUNTIME or vim.fn.getcwd()
vim.opt.rtp:prepend(root)
assert(
	#vim.api.nvim_get_runtime_file("autoload/vimtex/view/browser.vim", false) > 0,
	"browser viewer is missing from runtime"
)
assert(#vim.api.nvim_get_runtime_file("lua/core/tex_preview.lua", false) > 0, "preview module is missing from runtime")
local plugins = vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/opt/vimtex", false, true)
assert(#plugins > 0, "VimTeX must be installed")
vim.opt.rtp:append(plugins[1])
vim.cmd("runtime plugin/vimtex.vim")
vim.cmd("filetype plugin on")
require("plugins.configs.others").vimtex()
local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")
vim.g.vimtex_compiler_latexmk.out_dir = temp .. "/out"
vim.g.vimtex_compiler_latexmk.aux_dir = ""
local urls = {}
vim.ui.open = function(url)
	urls[#urls + 1] = url
end
local file = temp .. "/sample.tex"
vim.fn.writefile({ "\\documentclass{article}", "\\begin{document}", "First", "\\end{document}" }, file)
vim.cmd.edit(file)
vim.cmd("set ft=tex")
vim.fn["vimtex#init"]()
vim.cmd.VimtexCompile()
assert(
	vim.wait(30000, function()
		return #urls == 1
	end, 100),
	"first compilation did not open preview"
)
local function get(path)
	local result = vim.system({ "curl", "-fsS", urls[1] .. path }):wait()
	assert(result.code == 0, result.stderr)
	return result.stdout
end
local first = get("version")
assert(get("document.pdf"):sub(1, 5) == "%PDF-")
vim.api.nvim_buf_set_lines(0, 2, 3, false, { "Second revision" })
vim.cmd.write()
assert(
	vim.wait(15000, function()
		return get("version") ~= first
	end, 200),
	"PDF did not refresh"
)
assert(#urls == 1, "refresh opened another tab")
local second = get("version")
vim.api.nvim_buf_set_lines(0, 2, 3, false, { "\\undefinedcommand" })
vim.cmd.write()
vim.wait(3000, function()
	return false
end, 100)
assert(get("version") == second, "failed build replaced PDF")
vim.cmd.edit(file)
vim.cmd.VimtexView()
assert(#urls == 2 and urls[1] == urls[2], "manual view should reuse server")
vim.cmd.VimtexStop()
vim.api.nvim_exec_autocmds("VimLeavePre", { group = "tex_preview" })
assert(
	vim.wait(5000, function()
		return vim.system({ "curl", "-fsS", "--max-time", "1", urls[1] }):wait().code ~= 0
	end, 100),
	"preview server survived shutdown"
)
print("PASS: real build, refresh, single automatic tab, failed build, manual view")
vim.cmd("qa!")
