vim.opt.rtp:prepend(vim.fn.getcwd())
package.loaded["ndiff.tmux"] = { set_title = function() end }
local ndiff = require("ndiff")
local patch = vim.fn.tempname()
local lines = {}
for _, name in ipairs({ "a.txt", "b.txt" }) do
	vim.list_extend(
		lines,
		{ "diff --git a/" .. name .. " b/" .. name, "--- a/" .. name, "+++ b/" .. name, "@@ -1,150 +1,150 @@" }
	)
	for i = 1, 150 do
		table.insert(lines, "+line " .. i)
	end
end
vim.fn.writefile(lines, patch)
ndiff.open(patch)
vim.fn.delete(patch)
local main = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_cursor(main, { 120, 0 })
vim.cmd("normal! zt")
local explorer
for _, win in ipairs(vim.api.nvim_list_wins()) do
	if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "ndiff-files" then
		explorer = win
	end
end
vim.api.nvim_set_current_win(explorer)
vim.api.nvim_win_set_cursor(explorer, { 3, 0 })
ndiff.select_file()
assert(vim.api.nvim_win_get_cursor(main)[1] == 1, "new file inherited cursor position")
assert(vim.fn.winsaveview().topline == 1, "new file inherited scroll position")
print("ndiff scroll: ok")
for _, plugin in ipairs({ "plenary.nvim", "telescope.nvim" }) do
	local paths = vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/opt/" .. plugin, false, true)
	if #paths == 0 then
		paths = vim.fn.glob(vim.fn.stdpath("data") .. "/lazy/" .. plugin, false, true)
	end
	for _, path in ipairs(paths) do
		vim.opt.rtp:append(path)
	end
end
require("telescope").setup({ defaults = { file_ignore_patterns = { ".*" } } })
local function search(buffer, key, expected)
	vim.api.nvim_set_current_win(vim.fn.bufwinid(buffer))
	local mapping = vim.tbl_filter(function(m)
		return m.lhs == key
	end, vim.api.nvim_buf_get_keymap(buffer, "n"))[1]
	assert(mapping and mapping.callback, "missing diff search mapping")
	mapping.callback()
	local prompt = vim.api.nvim_get_current_buf()
	local picker = require("telescope.actions.state").get_current_picker(prompt)
	assert(#picker.finder.results == expected, "search escaped diff scope or lost entries")
	require("telescope.actions").close(prompt)
end
local main_buf = vim.api.nvim_win_get_buf(main)
search(main_buf, ",ff", 2)
search(main_buf, ",fw", 300)
search(vim.api.nvim_win_get_buf(explorer), ",fF", 2)
search(vim.api.nvim_win_get_buf(explorer), ",fW", 300)
print("ndiff search: ok")
vim.api.nvim_set_current_win(main)
vim.api.nvim_set_current_buf(main_buf)
local captured
package.loaded["ndiff.search"] = {
	open = function(entries, contents, select)
		captured = { entries = entries, contents = contents, select = select }
	end,
}
local mappings = vim.api.nvim_buf_get_keymap(main_buf, "n")
for _, mapping in ipairs(mappings) do
	if mapping.lhs == ",fw" then
		mapping.callback()
	end
end
local match = captured.entries[270]
captured.select(match.item, match.source)
assert(vim.api.nvim_get_current_line() == "+line 120", "search opened wrong line")
local explorer_buf = vim.api.nvim_win_get_buf(explorer)
vim.api.nvim_win_close(explorer, true)
vim.api.nvim_buf_delete(explorer_buf, { force = true })
vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(false, true))
local hidden_patch = vim.fn.tempname()
local context = {
	"diff --git a/deleted.txt b/deleted.txt",
	"--- a/deleted.txt",
	"+++ /dev/null",
	"@@ -1,150 +0,0 @@",
	"-removed needle",
}
for i = 1, 150 do
	table.insert(context, " context " .. i)
end
vim.fn.writefile(context, hidden_patch)
ndiff.open(hidden_patch, { open_tree = false, plain_files = { ["new.txt"] = "untracked needle\n" } })
vim.fn.delete(hidden_patch)
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
	if mapping.lhs == ",fw" then
		mapping.callback()
	end
end
local found = {}
for _, entry in ipairs(captured.entries) do
	found[entry.text] = entry
end
for _, text in ipairs({ "removed needle", "context 80", "untracked needle" }) do
	local entry = assert(found[text], "missing search content: " .. text)
	captured.select(entry.item, entry.source)
	assert(vim.api.nvim_get_current_line():find(text, 1, true), "wrong search destination")
end
print("ndiff search destinations and hidden/deleted/untracked content: ok")
