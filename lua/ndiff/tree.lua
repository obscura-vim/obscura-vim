local M = {}

local function add_path(root, item)
	local current = root
	for index, part in ipairs(vim.split(item.name, "/", { plain = true, trimempty = true })) do
		current[part] = current[part] or { children = {} }
		local node = current[part]
		if index == #vim.split(item.name, "/", { plain = true, trimempty = true }) then
			node.item = item
		end
		current = node.children
	end
end

local function render(nodes, depth, lines, items)
	local names = vim.tbl_keys(nodes)
	table.sort(names)
	for _, name in ipairs(names) do
		local node = nodes[name]
		local directory = next(node.children) ~= nil
		table.insert(lines, (depth == 0 and "" or string.rep("| ", depth)) .. name .. (directory and "/" or ""))
		items[#lines] = node.item
		if directory then
			render(node.children, depth + 1, lines, items)
		end
	end
end

function M.create(items)
	local root = {}
	for _, item in ipairs(items) do
		add_path(root, item)
	end
	local lines = { "../" }
	local line_items = {}
	render(root, 0, lines, line_items)
	return lines, line_items
end

return M
