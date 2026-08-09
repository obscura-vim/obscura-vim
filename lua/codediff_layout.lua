local M = {}
local states = {}

local function valid(win)
	return win and vim.api.nvim_win_is_valid(win)
end

local function get_windows(tabpage)
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	if not ok then
		return nil, nil
	end
	return lifecycle.get_windows(tabpage)
end

local function move_explorer_right(tabpage)
	local ok, lifecycle = pcall(require, "codediff.ui.lifecycle")
	if not ok then
		return
	end
	local session = lifecycle.get_session(tabpage)
	local explorer = session and session.explorer
	local win = explorer and explorer.winid
	if not valid(win) then
		return
	end
	vim.api.nvim_win_call(win, function()
		vim.cmd("wincmd L")
	end)
	vim.api.nvim_win_set_width(win, require("codediff.config").options.explorer.width)
end

local function collapse(tabpage, side)
	local original, modified = get_windows(tabpage)
	if not valid(original) or not valid(modified) or original == modified then
		return
	end
	local target = side == "original" and original or modified
	local other = side == "original" and modified or original
	vim.api.nvim_win_set_width(target, 1)
	if vim.api.nvim_get_current_win() == target then
		vim.api.nvim_set_current_win(other)
	end
	states[tabpage] = { collapsed = side }
end

local function restore(tabpage)
	local original, modified = get_windows(tabpage)
	if valid(original) and valid(modified) and original ~= modified then
		require("codediff.ui.layout").arrange(tabpage)
	end
	states[tabpage] = nil
end

local function enforce_state(tabpage)
	local state = states[tabpage]
	if not state or not state.collapsed then
		return
	end
	local original, modified = get_windows(tabpage)
	local target = state.collapsed == "original" and original or modified
	if valid(target) and vim.api.nvim_win_get_width(target) ~= 1 then
		collapse(tabpage, state.collapsed)
	end
end

function M.toggle(side)
	local tabpage = vim.api.nvim_get_current_tabpage()
	local state = states[tabpage]
	if state and state.collapsed == side then
		restore(tabpage)
	else
		collapse(tabpage, side)
	end
end

local function bind(tabpage)
	local lifecycle = require("codediff.ui.lifecycle")
	lifecycle.set_tab_keymap(tabpage, "n", "<C-e>", function()
		local session = lifecycle.get_session(tabpage)
		local explorer = session and session.explorer
		if not explorer then
			return
		end
		require("codediff.ui.explorer.actions").toggle_visibility(explorer)
		vim.schedule(function()
			if vim.api.nvim_tabpage_is_valid(tabpage) then
				move_explorer_right(tabpage)
				enforce_state(tabpage)
			end
		end)
	end, { desc = "Toggle diff file explorer" })
	lifecycle.set_tab_keymap(tabpage, "n", "[", function()
		M.toggle("original")
	end, { desc = "Toggle original diff pane" })
	lifecycle.set_tab_keymap(tabpage, "n", "]", function()
		M.toggle("modified")
	end, { desc = "Toggle modified diff pane" })
end

function M.setup()
	vim.api.nvim_create_autocmd("WinResized", {
		callback = function()
			vim.schedule(function()
				for tabpage, state in pairs(states) do
					if vim.api.nvim_tabpage_is_valid(tabpage) and state.collapsed then
						enforce_state(tabpage)
					end
				end
			end)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
		callback = function()
			local tabpage = vim.api.nvim_get_current_tabpage()
			vim.schedule(function()
				if not vim.api.nvim_tabpage_is_valid(tabpage) then
					return
				end
				local lifecycle = require("codediff.ui.lifecycle")
				if lifecycle.get_session(tabpage) then
					bind(tabpage)
					enforce_state(tabpage)
				end
			end)
		end,
	})

	vim.api.nvim_create_autocmd("BufWinEnter", {
		callback = function(args)
			if vim.bo[args.buf].filetype ~= "codediff-explorer" then
				return
			end
			local tabpage = vim.api.nvim_get_current_tabpage()
			vim.schedule(function()
				if vim.api.nvim_tabpage_is_valid(tabpage) then
					move_explorer_right(tabpage)
					enforce_state(tabpage)
				end
			end)
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = { "CodeDiffOpen", "CodeDiffFileSelect" },
		callback = function(args)
			local tabpage = args.data and args.data.tabpage or vim.api.nvim_get_current_tabpage()
			vim.schedule(function()
				if vim.api.nvim_tabpage_is_valid(tabpage) then
					move_explorer_right(tabpage)
					bind(tabpage)
					enforce_state(tabpage)
				end
			end)
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "CodeDiffClose",
		callback = function(args)
			local tabpage = args.data and args.data.tabpage
			if tabpage then
				states[tabpage] = nil
			end
		end,
	})
end

return M
