local M = { context_lines = 10 }

function M.setup(options)
	if options and options.context_lines then
		M.context_lines = math.max(0, math.floor(options.context_lines))
	end
end

return M
