local M = {}

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
	return root ~= "" and inside(root, cwd) and root or nil
end

local function repository_root(path)
	local cwd = canonical(vim.fs.dirname(path))
	local roots = {}
	local arc_root = command_root({ "arc", "root" }, cwd)
	local git_root = command_root({ "git", "rev-parse", "--show-toplevel" }, cwd)
	if arc_root then
		table.insert(roots, arc_root)
	end
	if git_root then
		table.insert(roots, git_root)
	end
	table.sort(roots, function(left, right)
		return #left > #right
	end)
	return roots[1]
end

local function format_link(path, first, last)
	local suffix = first == last and ("L%d"):format(first) or ("L%d-%d"):format(first, last)
	return path .. ":" .. suffix
end

local function copy(link)
	vim.fn.setreg("+", link)
	vim.fn.setreg('"', link)
	vim.notify("Copied: " .. link)
	return link
end

local function visual_range()
	local first = vim.fn.line("v")
	local last = vim.fn.line(".")
	return math.min(first, last), math.max(first, last)
end

function M.copy_buffer_selection()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		vim.notify("Cannot copy a code link for an unnamed buffer", vim.log.levels.ERROR)
		return nil
	end
	local path = canonical(name)
	local root = repository_root(path)
	if not root then
		vim.notify("Cannot find a Git or Arc repository", vim.log.levels.ERROR)
		return nil
	end
	local first, last = visual_range()
	return copy(format_link(path:sub(#root + 2), first, last))
end

local function selected_source_lines(lines, first, last)
	local positions = {}
	local old_line
	local new_line
	for index, line in ipairs(lines) do
		local old_start, new_start = line:match("^@@ %-(%d+),?%d* %+(%d+),?%d* @@")
		if old_start then
			old_line = tonumber(old_start)
			new_line = tonumber(new_start)
		elseif old_line and new_line then
			local prefix = line:sub(1, 1)
			if index >= first and index <= last then
				if prefix == "-" then
					table.insert(positions, old_line)
				elseif prefix == "+" or prefix == " " then
					table.insert(positions, new_line)
				end
			end
			if prefix == " " then
				old_line = old_line + 1
				new_line = new_line + 1
			elseif prefix == "-" then
				old_line = old_line + 1
			elseif prefix == "+" then
				new_line = new_line + 1
			end
		end
	end
	return positions
end

function M.copy_diff_selection(path, lines, first, last)
	local positions = selected_source_lines(lines, math.min(first, last), math.max(first, last))
	if #positions == 0 then
		vim.notify("The selection does not contain source lines", vim.log.levels.ERROR)
		return nil
	end
	table.sort(positions)
	return copy(format_link(path, positions[1], positions[#positions]))
end

function M.copy_path_selection(path, first, last)
	return copy(format_link(path, math.min(first, last), math.max(first, last)))
end

return M
