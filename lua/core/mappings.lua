local map = vim.keymap.set

map("i", "<C-a>", "<ESC>^i", { desc = "Beginning of line" })
map("i", "<C-e>", "<End>", { desc = "End of line" })

map("n", "'", "`", { noremap = true })
map("n", "`", "'", { noremap = true })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "Clear highlights" })

map("n", "<C-BS>", "<ESC>dbi", { desc = "Delete previous word" })
map("i", "<A-BS>", "<ESC>dbi<DEL>", { desc = "Delete previous word" })

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })

map("n", "<S-d>", "<C-e>", { desc = "Scroll down" })
map("n", "<S-u>", "<C-y>", { desc = "Scroll up" })

map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "Copy whole file" })

map("n", "<C-p>", "<cmd>let @+=expand('%:p')<CR>", { desc = "Copy absolute path of current file" })

map("n", "<leader>n", "<cmd>set nu!<CR>", { desc = "Toggle line number" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "Toggle relative number" })

map("n", "<leader>z", "<cmd>bufdo bd<CR>", { desc = "Dashboard" })

map("n", "<leader>x", "<cmd>bd<CR>", { desc = "Close buffer" })

map("n", "gq", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format code with Conform" })

map("n", "<leader>b", "<cmd>VimtexCompile<CR>", { desc = "Build latex doc" })

map("n", "<leader>m", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Preview markdown document in Github style" })

map("n", "<leader>p", function()
	local buf = vim.api.nvim_get_current_buf()
	if vim.b[buf].hard_writer_on then
		vim.cmd("NoPencil")
		vim.b[buf].hard_writer_on = false
		vim.cmd('echo "Writer mode off"')
	else
		vim.cmd("PencilHard")
		vim.b[buf].hard_writer_on = true
		vim.cmd('echo "Writer mode on"')
	end
end, { desc = "Toggle pencil hard mode with log" })

map("n", "<leader>v", "<cmd>VimtexView<CR>", { desc = "View place in latex doc" })

map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })

map("n", "<Leader>-", "<cmd>vsplit<CR>")
map("n", "<Leader>=", "<cmd>split<CR>")

map("n", ".", ".")

map("n", "<C-n>", "<cmd>b#<CR>", { desc = "Go to previous buffer", noremap = true, silent = true })

map("n", "<leader>rp", "<cmd>!python %<CR>", { desc = "Fast run python file" })
map("n", "<leader>rr", "<cmd>RustRun<CR>", { desc = "Fast run rust file" })
map("n", "<leader>rl", "<cmd>!lua %<CR>", { desc = "Fast run lua file" })
map("n", "<leader>rg", "<cmd>!go run %<CR>", { desc = "Fast run go file" })
map(
	"n",
	"<leader>rc",
	"<cmd>!gcc -Wall -Werror -O2 -g -std=gnu17 -fsanitize=undefined,address % -o %:r && ./%:r<CR>",
	{ desc = "Fast run C file" }
)

map("t", "<Esc>", vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), { desc = "Escape terminal mode" })

map("v", "<", "<gv", { desc = "Indent line" })
map("v", ">", ">gv", { desc = "Indent line" })

map("n", ",c", function()
	require("Comment.api").toggle.linewise.current()
end, { desc = "Toggle comment" })

map(
	"v",
	",c",
	"<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
	{ desc = "Toggle comment" }
)

map("i", "<C-l>", function()
	vim.lsp.buf.signature_help()
end, { desc = "LSP signature help" })

map("n", "gd", function()
	vim.lsp.buf.definition()
end, { desc = "LSP definition" })

map("n", "K", function()
	vim.lsp.buf.hover({ border = "rounded" })
end, { desc = "LSP hover" })

map("n", "E", function()
	vim.diagnostic.open_float({ border = "rounded" })
end, { desc = "Floating diagnostic" })

map("n", "<leader>q", function()
	vim.diagnostic.setloclist()
end, { desc = "Diagnostic setloclist" })

map("v", "<C-r>", function()
	vim.cmd('normal! "zy')
	local query = vim.fn.getreg("z")
	if not query or query == "" then
		return
	end

	query = query:gsub("\n", " ")
	query = vim.fn.shellescape(query)

	vim.cmd("enew")
	vim.cmd("terminal rgr " .. query)
	vim.cmd("startinsert")

	vim.api.nvim_create_autocmd("TermClose", {
		buffer = 0,
		once = true,
		callback = function()
			vim.schedule(function()
				vim.cmd("bdelete! " .. vim.fn.bufnr("%"))
			end)
		end,
	})
end, { desc = "Rename with rgr" })

map("n", "<C-e>", "<cmd>Oil<CR>", { desc = "Open oil file manager" })

map("n", ",ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })

map("n", ",fF", function()
	require("telescope.builtin").find_files({
		no_ignore = true,
		hidden = true,
		file_ignore_patterns = {},
	})
end, { desc = "Find all files" })

map("n", ",fw", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })

map("n", ",fW", function()
	require("telescope.builtin").live_grep({
		additional_args = function(_)
			return { "--hidden", "--no-ignore", "-L" }
		end,
		file_ignore_patterns = {},
	})
end, { desc = "Live grep (all files, hidden, no-ignore, follow)" })

map("n", "<Tab>", function()
	local bufs = vim.tbl_filter(function(b)
		return vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b) ~= ""
	end, vim.api.nvim_list_bufs())
	require("telescope.builtin").buffers({ buf_ids = bufs, sort_lastused = true })
end, { desc = "Find buffers" })

map("n", ",fo", "<cmd>Telescope oldfiles<CR>", { desc = "Find oldfiles" })
map("n", ",fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Find in current buffer" })

map("n", ",fc", "<cmd>Telescope git_commits<CR>", { desc = "Git commits" })
map("n", ",fg", "<cmd>Telescope git_status<CR>", { desc = "Git status" })

map("n", ",fm", "<cmd>Telescope marks<CR>", { desc = "telescope bookmarks" })

map("n", "<A-j>", "<cmd>CoqNext<CR>", { desc = "Next coq line", noremap = true, silent = true })
map("n", "<F-k>", "<cmd>CoqUndo<CR>", { desc = "Prev coq line", noremap = true, silent = true })
map("n", "<A-m>", "<cmd> CoqToLine <CR>", { noremap = true, silent = true })
map("n", "<leader>sc", "<cmd> CoqStart <CR>", { noremap = true, silent = true })

map("n", "<leader>lr", function()
	vim.cmd("LeanAbbreviationsReverseLookup")
end, { noremap = true, silent = true, desc = "Lean: Reverse Abbreviation Lookup" })

map("i", "<C-.>", "\\Rightarrow", { desc = "Latex right arrow" })
map("i", "<C-,>", "\\Leftarrow", { desc = "Latex left arrow" })

local M = {}

M.ufo = {
	zR = function()
		require("ufo").openAllFolds()
	end,
	zM = function()
		require("ufo").closeAllFolds()
	end,
	["<leader>h"] = function()
		local winid = vim.api.nvim_get_current_win()
		if vim.api.nvim_win_get_config(winid).relative ~= "" then
			return
		end

		local lnum = vim.api.nvim_win_get_cursor(winid)[1]
		local is_closed = vim.fn.foldclosed(lnum)
		local is_open = vim.fn.foldlevel(lnum) > 0 and is_closed == -1

		if is_closed ~= -1 then
			vim.cmd("normal! zo")
		elseif is_open then
			vim.cmd("normal! zc")
		end
	end,
}

M.colorizer = {
	["<leader>c"] = function()
		if not vim.g.colorizer_loaded then
			require("colorizer").setup()
			vim.g.colorizer_loaded = true
		end
		vim.cmd("ColorizerToggle")
	end,
}

M.ibl = {
	["<leader>i"] = function()
		local loaded, _ = pcall(require, "ibl")
		if not loaded then
			vim.notify("Failed to load indent-blankline.nvim", vim.log.levels.WARN)
			return
		end
		vim.cmd("IBLToggle")
	end,
}

M.gitsigns = {
	["<leader>g"] = function()
		if not vim.g.gitsigns_loaded then
			local loaded, gitsigns = pcall(require, "gitsigns")
			if not loaded then
				vim.notify("Failed to load gitsigns.nvim", vim.log.levels.WARN)
				return
			end

			gitsigns.setup({
				signs = {
					add = { text = "▎" },
					change = { text = "▎" },
					delete = { text = "▎" },
					topdelete = { text = "▎" },
					changedelete = { text = "▎" },
				},
				signcolumn = true,
				numhl = false,
				linehl = false,
				current_line_blame = false,
				word_diff = false,
				watch_gitdir = {
					interval = 1000,
					follow_files = true,
				},
				update_debounce = 200,
			})

			vim.g.gitsigns_loaded = true
		else
			local gitsigns = require("gitsigns")
			local _ = vim.api.nvim_get_current_buf()
			local active = gitsigns.toggle_signs()
			vim.notify("Gitsigns " .. (active and "enabled" or "disabled"))
		end
	end,
}

return M
