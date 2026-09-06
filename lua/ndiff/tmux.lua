local M = {}

function M.set_title()
	local pane = vim.env.TMUX_PANE
	if not vim.env.TMUX or not pane or pane == "" then
		return
	end
	local window = vim.trim(vim.system({ "tmux", "display-message", "-p", "-t", pane, "#{window_id}" }, { text = true }):wait().stdout or "")
	if window == "" then
		return
	end
	local automatic = vim.trim(vim.system({ "tmux", "show-window-options", "-v", "-t", window, "automatic-rename" }, { text = true }):wait().stdout or "")
	local name = vim.trim(vim.system({ "tmux", "display-message", "-p", "-t", window, "#{window_name}" }, { text = true }):wait().stdout or "")
	vim.system({ "tmux", "set-window-option", "-t", window, "automatic-rename", "off" }):wait()
	vim.system({ "tmux", "rename-window", "-t", window, "ndiff" }):wait()
	vim.api.nvim_create_autocmd("VimLeavePre", {
		once = true,
		callback = function()
			if automatic == "on" then
				vim.system({ "tmux", "set-window-option", "-t", window, "automatic-rename", "on" }):wait()
			elseif name ~= "" then
				vim.system({ "tmux", "rename-window", "-t", window, name }):wait()
			end
		end,
	})
end

return M
