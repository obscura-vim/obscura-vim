local M = {}
local state = {}
local FULL_CONTEXT = 1000000
local config = require("ndiff.config")
local tmux = require("ndiff.tmux")
local tree = require("ndiff.tree")

local function is_header(line)
	return line:match("^diff %-%-git ") or line:match("^diff %-ruN ")
end

local function split_sections(lines)
	local result = {}
	local start = 1
	for index, line in ipairs(lines) do
		if index > 1 and is_header(line) then
			table.insert(result, { start = start, finish = index - 1 })
			start = index
		end
	end
	if #lines >= start then
		table.insert(result, { start = start, finish = #lines })
	end
	return result
end

local function section_name(lines, item, index)
	for line = item.start, item.finish do
		local _, git_path = lines[line]:match("^diff %-%-git a/(.-) b/(.*)$")
		if git_path then
			return git_path
		end
		local after_path = lines[line]:match("^diff %-ruN .*/after/(.*)$")
		if after_path then
			return after_path
		end
		local path = lines[line]:match("^%+%+%+ [ab]/(.*)$")
		if path then
			return path
		end
	end
	return ("diff-%d"):format(index)
end

local function context_ranges(lines)
	local ranges = {}
	local run_start
	local function finish_run(run_end)
		if run_start and run_end - run_start + 1 > config.context_lines * 2 then
			table.insert(ranges, {
				first = run_start + config.context_lines,
				last = run_end - config.context_lines,
			})
		end
		run_start = nil
	end
	for index, line in ipairs(lines) do
		if line:sub(1, 1) == " " then
			run_start = run_start or index
		else
			finish_run(index - 1)
		end
	end
	finish_run(#lines)
	return ranges
end

local function hidden_context_line(count)
	return ("⋯ %d unchanged lines hidden — <Space> to reveal"):format(count)
end

local function is_patch_metadata(line)
	return line:match("^diff %-%-git ")
		or line:match("^index ")
		or line:match("^%-%-%- ")
		or line:match("^%+%+%+ ")
		or line:match("^@@ ")
		or line:match("^\\ No newline at end of file")
end

local function content_lines(lines)
	local result = {}
	local source_lines = {}
	for index, line in ipairs(lines) do
		if not is_patch_metadata(line) then
			table.insert(result, line)
			table.insert(source_lines, index)
		end
	end
	return result, source_lines
end

local function display_lines(lines, source_lines)
	local result = {}
	local hidden = {}
	local displayed_sources = {}
	local cursor = 1
	for _, range in ipairs(context_ranges(lines)) do
		vim.list_extend(result, vim.list_slice(lines, cursor, range.first - 1))
		vim.list_extend(displayed_sources, vim.list_slice(source_lines, cursor, range.first - 1))
		local index = #result + 1
		table.insert(result, hidden_context_line(range.last - range.first + 1))
		table.insert(displayed_sources, false)
		hidden[index] = { lines = vim.list_slice(lines, range.first, range.last), sources = vim.list_slice(source_lines, range.first, range.last) }
		cursor = range.last + 1
	end
	vim.list_extend(result, vim.list_slice(lines, cursor))
	vim.list_extend(displayed_sources, vim.list_slice(source_lines, cursor))
	return result, hidden, displayed_sources
end

local function configure_diff_highlights()
	local namespace = vim.api.nvim_create_namespace("ndiff")
	for _, name in ipairs({ "DiffAdd", "DiffChange", "DiffDelete", "DiffText" }) do
		local highlight = vim.api.nvim_get_hl(0, { name = name, link = false })
		vim.api.nvim_set_hl(namespace, name, { fg = highlight.fg, bold = highlight.bold, italic = highlight.italic, underline = highlight.underline })
	end
	vim.api.nvim_set_hl(namespace, "NdiffHiddenContext", { link = "Comment" })
	state.highlight_namespace = namespace
	vim.api.nvim_win_set_hl_ns(state.main_window, namespace)
end

local function show_section(item)
	if not item or not vim.api.nvim_buf_is_valid(state.main) then
		return
	end
	local lines
	local filetype
	if item.plain_content ~= nil then
		lines = vim.split(item.plain_content, "\n", { plain = true })
		if lines[#lines] == "" then
			table.remove(lines)
		end
		filetype = vim.filetype.match({ filename = item.name }) or ""
	else
		lines = vim.list_slice(state.lines, item.start, item.finish)
		filetype = "diff"
	end
	vim.bo[state.main].modifiable = true
	local displayed
	local hidden
	local displayed_sources
	if item.plain_content == nil then
		local content
		local source_lines
		content, source_lines = content_lines(lines)
		displayed, hidden, displayed_sources = display_lines(content, source_lines)
	else
		displayed, hidden, displayed_sources = lines, {}, {}
	end
	vim.api.nvim_buf_set_lines(state.main, 0, -1, false, displayed)
	vim.bo[state.main].modifiable = false
	vim.bo[state.main].modified = false
	vim.bo[state.main].filetype = filetype
	state.selected = item
	state.hidden_context = hidden
	state.raw_lines = lines
	state.displayed_sources = displayed_sources
	vim.api.nvim_set_current_win(state.main_window)
	configure_diff_highlights()
	for line in pairs(hidden) do
		vim.api.nvim_buf_add_highlight(state.main, state.highlight_namespace, "NdiffHiddenContext", line - 1, 0, -1)
	end
end

local function reveal_context()
	local line = vim.api.nvim_win_get_cursor(state.main_window)[1]
	local hidden = state.hidden_context and state.hidden_context[line]
	if not hidden then
		return
	end
	vim.bo[state.main].modifiable = true
	vim.api.nvim_buf_set_lines(state.main, line - 1, line, false, hidden.lines)
	vim.bo[state.main].modifiable = false
	vim.bo[state.main].modified = false
	local remaining = {}
	for index, value in pairs(state.hidden_context) do
		if index > line then
			remaining[index + #hidden.lines - 1] = value
		end
	end
	local sources = state.displayed_sources
	table.remove(sources, line)
	for index, source in ipairs(hidden.sources) do
		table.insert(sources, line + index - 1, source)
	end
	state.hidden_context = remaining
end

local function select_file()
	local index = vim.api.nvim_win_get_cursor(0)[1]
	show_section(state.line_items[index])
end

local function copy_code_link()
	local first = vim.fn.line("v")
	local last = vim.fn.line(".")
	if state.selected.plain_content ~= nil then
		require("code_link").copy_path_selection(state.selected.name, first, last)
		return
	end
	local source_first = state.displayed_sources[first]
	local source_last = state.displayed_sources[last]
	if not source_first or not source_last then
		vim.notify("Reveal hidden context before copying it", vim.log.levels.WARN)
		return
	end
	require("code_link").copy_diff_selection(state.selected.name, state.raw_lines, source_first, source_last)
end

local function toggle_explorer()
	if state.explorer_window and vim.api.nvim_win_is_valid(state.explorer_window) then
		vim.api.nvim_win_close(state.explorer_window, false)
		state.explorer_window = nil
		return
	end
	vim.api.nvim_set_current_win(state.main_window)
	vim.cmd("rightbelow vsplit")
	state.explorer_window = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(state.explorer_window, 36)
	vim.api.nvim_win_set_buf(state.explorer_window, state.explorer)
	vim.api.nvim_set_current_win(state.main_window)
end

M.select_file = select_file
M.toggle_explorer = toggle_explorer
M.reveal_context = reveal_context

local function command(args, cwd, accepted)
	local result = vim.system(args, { cwd = cwd, text = true }):wait()
	if result.code == 0 or (accepted and accepted[result.code]) then
		return result.stdout or ""
	end
	error(vim.trim(result.stderr or "") ~= "" and vim.trim(result.stderr) or table.concat(args, " ") .. " failed")
end

local function canonical(path)
	local normalized = vim.fs.normalize(path)
	return vim.uv.fs_realpath(normalized) or normalized
end

local function inside(root, path)
	return path == root or path:sub(1, #root + 1) == root .. "/"
end

local function command_root(args, cwd)
	local result = vim.system(args, { cwd = cwd, text = true }):wait()
	if result.code ~= 0 then
		return nil
	end
	local root = canonical(vim.trim(result.stdout or ""))
	return root ~= "" and inside(root, canonical(cwd)) and root or nil
end

local function repository(cwd)
	local candidates = {}
	local arc_root = command_root({ "arc", "root" }, cwd)
	local git_root = command_root({ "git", "rev-parse", "--show-toplevel" }, cwd)
	if arc_root then
		table.insert(candidates, { vcs = "arc", root = arc_root })
	end
	if git_root then
		table.insert(candidates, { vcs = "git", root = git_root })
	end
	table.sort(candidates, function(left, right)
		return #left.root > #right.root
	end)
	return candidates[1]
end

local function normalize_paths(root, cwd, values)
	local result = {}
	for _, value in ipairs(values) do
		local path = canonical(value:sub(1, 1) == "/" and value or (cwd .. "/" .. value))
		if not inside(root, path) then
			error("path is outside repository: " .. value)
		end
		table.insert(result, path == root and "." or path:sub(#root + 2))
	end
	return result
end

local function path_selected(path, paths)
	if #paths == 0 then
		return true
	end
	for _, selected in ipairs(paths) do
		if selected == "." or path == selected or path:sub(1, #selected + 1) == selected .. "/" then
			return true
		end
	end
	return false
end

local function read_file(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

local function file_patch(path, before, after)
	local ok, body = pcall(vim.diff, before or "", after or "", { result_type = "unified", ctxlen = FULL_CONTEXT })
	if not ok then
		return "diff --git a/" .. path .. " b/" .. path .. "\nBinary files differ\n"
	end
	if body == "" then
		return ""
	end
	local old_path = before == nil and "/dev/null" or "a/" .. path
	local new_path = after == nil and "/dev/null" or "b/" .. path
	return "diff --git a/" .. path .. " b/" .. path .. "\n--- " .. old_path .. "\n+++ " .. new_path .. "\n" .. body
end

local function git_worktree_patch(root, paths)
	local args = { "git", "diff", "--no-ext-diff", "--no-color", "--unified=" .. FULL_CONTEXT, "HEAD" }
	if #paths > 0 then
		table.insert(args, "--")
		vim.list_extend(args, paths)
	end
	local patch = command(args, root)
	local plain_files = {}
	local status = command({ "git", "status", "--porcelain=v1", "-z", "--untracked-files=all" }, root)
	for entry in status:gmatch("([^%z]+)") do
		if entry:sub(1, 2) == "??" then
			local path = entry:sub(4)
			if path_selected(path, paths) then
				local content = read_file(root .. "/" .. path)
				if content then
					plain_files[path] = content
				end
			end
		end
	end
	return patch, plain_files
end

local function arc_worktree_patch(root, paths)
	local status = command({ "arc", "status", "--json", "-u", "all" }, root)
	local decoded = vim.json.decode(status)
	local entries = decoded.status or {}
	local patch = ""
	local plain_files = {}
	for _, entry in ipairs(entries.changed or {}) do
		local path = entry.path
		if type(path) == "string" and path_selected(path, paths) then
			local original = vim.system({ "arc", "show", "HEAD:" .. path }, { cwd = root, text = true }):wait()
			local before = original.code == 0 and original.stdout or nil
			local after = read_file(root .. "/" .. path)
			patch = patch .. file_patch(path, before, after)
		end
	end
	for _, entry in ipairs(entries.untracked or {}) do
		local path = entry.path
		if type(path) == "string" and path_selected(path, paths) then
			local content = read_file(root .. "/" .. path)
			if content then
				plain_files[path] = content
			end
		end
	end
	return patch, plain_files
end

local function branch_name(vcs, root)
	if vcs == "git" then
		return vim.trim(command({ "git", "symbolic-ref", "--quiet", "--short", "HEAD" }, root))
	end
	local info = command({ "arc", "info" }, root)
	return info:match("\n?branch: ([^\n]+)")
end

local function json_value(value, keys)
	if type(value) ~= "table" then
		return nil
	end
	for key, item in pairs(value) do
		if keys[key] and item ~= nil and item ~= "" then
			return item
		end
	end
	for _, item in pairs(value) do
		local found = json_value(item, keys)
		if found ~= nil then
			return found
		end
	end
	return nil
end

local function pull_request_patch(vcs, root)
	local branch = branch_name(vcs, root)
	if not branch or branch == "" then
		error("current repository state has no branch")
	end
	if vcs == "git" then
		local metadata = vim.json.decode(command({ "gh", "pr", "view", branch, "--json", "number,baseRefOid,headRefOid" }, root))
		local number = json_value(metadata, { number = true })
		if not number then
			error("GitHub PR not found for the current branch")
		end
		local base = json_value(metadata, { baseRefOid = true })
		local head = json_value(metadata, { headRefOid = true })
		if base and head then
			local result = vim.system(
				{ "git", "diff", "--no-ext-diff", "--no-color", "--unified=" .. FULL_CONTEXT, tostring(base), tostring(head) },
				{ cwd = root, text = true }
			):wait()
			if result.code == 0 then
				return result.stdout or ""
			end
		end
		return command({ "gh", "pr", "diff", tostring(number), "--patch", "--color", "never" }, root)
	end
	local metadata = vim.json.decode(command({ "arc", "pr", "status", "--json", branch }, root))
	local id = json_value(metadata, { id = true, pr_id = true, pull_request_id = true })
	if not id then
		error("Arcadia PR not found for the current branch")
	end
	return command({ "arc", "pr", "changes", tostring(id) }, root)
end

local function commit_patch(vcs, root, revision)
	revision = revision or "HEAD"
	if vcs == "git" then
		return command({ "git", "show", "--patch", "--format=", "--no-ext-diff", "--no-color", "--unified=" .. FULL_CONTEXT, revision }, root)
	end
	return command({ "arc", "show", "--git", "--no-color", "-U", tostring(FULL_CONTEXT), revision }, root)
end

local function clean_patch(patch)
	return patch:gsub("\27%[[0-?]*[ -/]*[@-~]", "")
end

local function open_patch(patch, options)
	patch = clean_patch(patch)
	local lines = {}
	if patch ~= "" then
		lines = vim.split(patch, "\n", { plain = true })
		if lines[#lines] == "" then
			table.remove(lines)
		end
	end

	local items = #lines > 0 and split_sections(lines) or {}
	for index, item in ipairs(items) do
		item.name = section_name(lines, item, index)
	end
	for name, content in pairs(options and options.plain_files or {}) do
		table.insert(items, { name = name, plain_content = content })
	end
	if #items == 0 then
		vim.notify("ndiff: no changes")
		return
	end
	local tree_lines, line_items = tree.create(items)
	state = { lines = lines, items = items, line_items = line_items }
	state.main = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.main, "ndiff-diff")
	vim.api.nvim_set_current_buf(state.main)
	state.main_window = vim.api.nvim_get_current_win()
	vim.bo[state.main].bufhidden = "wipe"
	vim.bo[state.main].filetype = "diff"

	state.explorer = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(state.explorer, "ndiff-files")
	vim.api.nvim_buf_set_lines(state.explorer, 0, -1, false, tree_lines)
	vim.bo[state.explorer].buftype = "nofile"
	vim.bo[state.explorer].bufhidden = "hide"
	vim.bo[state.explorer].modifiable = false
	vim.bo[state.explorer].filetype = "ndiff-files"
	vim.api.nvim_set_hl(0, "NdiffUntracked", { default = true, link = "Added" })
	for index, item in pairs(line_items) do
		if item.plain_content ~= nil then
			local name = vim.fs.basename(item.name)
			local start = #tree_lines[index] - #name
			vim.api.nvim_buf_add_highlight(state.explorer, -1, "NdiffUntracked", index - 1, start, -1)
		end
	end
	vim.keymap.set("n", "<CR>", select_file, { buffer = state.explorer, silent = true })
	vim.keymap.set("n", "<C-e>", toggle_explorer, { buffer = state.explorer, silent = true })
	vim.keymap.set("n", "<C-e>", toggle_explorer, { buffer = state.main, silent = true })
	vim.keymap.set("n", "<Space>", reveal_context, { buffer = state.main, silent = true, desc = "Reveal hidden diff context" })
	vim.keymap.set("x", "<C-y>", copy_code_link, { buffer = state.main, silent = true, desc = "Copy code link" })

	show_section(items[1])
	if not options or options.open_tree ~= false then
		toggle_explorer()
	end
	vim.cmd("redraw")
	vim.schedule(tmux.set_title)
end

function M.setup(options)
	config.setup(options)
end

function M.open(path, options)
	local file = io.open(path, "r")
	if not file then
		vim.notify("ndiff: cannot read diff", vim.log.levels.ERROR)
		return
	end
	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()
	open_patch(table.concat(lines, "\n"), options)
end

function M.start(arguments)
	local ok, error_message = pcall(function()
		local args = vim.deepcopy(arguments or {})
		for index = #args, 1, -1 do
			if args[index] == "--dry-run" then
				table.remove(args, index)
			end
		end
		local cwd = canonical(vim.uv.cwd())
		local detected = repository(cwd)
		if not detected then
			error("not inside a Git or Arc repository")
		end
		local patch
		local plain_files
		local open_tree = true
		if args[1] == "pr" then
			if #args > 1 then
				error("the pr mode does not accept path arguments")
			end
			patch = pull_request_patch(detected.vcs, detected.root)
		elseif args[1] == "commit" then
			if #args > 2 then
				error("the commit mode accepts at most one revision")
			end
			patch = commit_patch(detected.vcs, detected.root, args[2])
		else
			local paths = normalize_paths(detected.root, cwd, args)
			open_tree = #paths == 0
			if detected.vcs == "git" then
				patch, plain_files = git_worktree_patch(detected.root, paths)
			else
				patch, plain_files = arc_worktree_patch(detected.root, paths)
			end
		end
		open_patch(patch, { open_tree = open_tree, plain_files = plain_files })
	end)
	if not ok then
		vim.notify("ndiff: " .. tostring(error_message), vim.log.levels.ERROR)
	end
end

return M
