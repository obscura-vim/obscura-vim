local M = {}

function M.open(entries, contents, select)
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values
	require("telescope.pickers")
		.new({}, {
			file_ignore_patterns = {},
			prompt_title = contents and "Diff contents" or "Diff files",
			finder = require("telescope.finders").new_table({
				results = entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = contents and (entry.item.name .. ":" .. entry.source .. ": " .. entry.text)
							or entry.text,
						ordinal = entry.text,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if entry then
						select(entry.value.item, entry.value.source)
					end
				end)
				return true
			end,
		})
		:find()
end

return M
