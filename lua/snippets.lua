local M = {}

local snippets = {
	python = { pprint = "from pprint import pprint\npprint(${1})" },
	markdown = { ["---"] = "— ${0}" },
	tex = {
		["not"] = "\\overline{${1}}",
		fr = "\\frac{${1}}{${2}}",
		an = "\\begin{align}\n\t${1}\n\\end{align}",
		a = "\\begin{align*}\n\t${1}\n\\end{align*}",
		g = "\\begin{gather*}\n\t${1}\n\\end{gather*}",
		div = "\\ \\vdots \\ ${1}",
		[">="] = "\\geqslant ${1}",
		["<="] = "\\eqslantless ${1}",
		["<=>"] = "\\Leftrightarrow ${1}",
		["->"] = "\\longrightarrow ${1}",
		["<-"] = "\\longleftarrow ${1}",
		bf = "\\textbf{${1}}",
		enum = "\\begin{enumerate}\n\t${1}\n\\end{enumerate}",
		sys = "\\begin{cases}\n\t${1}\n\\end{cases}",
		lim = "\\lim\\limits_{${1} \\to ${2}}{${3}} ${4}",
		inf = "\\infty${1}",
		pm = "\\begin{pmatrix}\n\t${1}\n\\end{pmatrix}",
		vm = "\\begin{vmatrix}\n\t${1}\n\\end{vmatrix}",
		fig = "\\begin{figure}[ht]\n\t\\centering\n\t\\includegraphics[width=1\\textwidth]{../../../figures/${1}.png}\n\\end{figure}",
	},
}

function M.expand()
	local row, column = unpack(vim.api.nvim_win_get_cursor(0))
	local trigger = vim.api.nvim_get_current_line():sub(1, column + 1):match("[^%s]+$")
	local body = trigger and snippets[vim.bo.filetype] and snippets[vim.bo.filetype][trigger]
	if not body then
		return false
	end
	vim.schedule(function()
		local current_row, current_column = unpack(vim.api.nvim_win_get_cursor(0))
		local end_column = math.min(current_column + 1, #vim.api.nvim_get_current_line())
		vim.api.nvim_buf_set_text(0, current_row - 1, end_column - #trigger, current_row - 1, end_column, { "" })
		vim.snippet.expand(body)
	end)
	return true
end

return M
