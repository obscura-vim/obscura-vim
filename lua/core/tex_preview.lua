local M = {}
local sessions = {}
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")

local function open(url)
	local _, err = vim.ui.open(url)
	if err then
		vim.notify(tostring(err), vim.log.levels.ERROR)
	end
end

local function start(file)
	local session = { output = "" }
	sessions[file] = session
	session.job = vim.fn.jobstart({ "python3", root .. "/scripts/tex_preview.py", file }, {
		on_stdout = function(_, lines)
			lines[1] = session.output .. lines[1]
			session.output = lines[#lines]
			for i = 1, #lines - 1 do
				local line = lines[i]
				if line:match("^http://127%.0%.0%.1:") then
					session.url = line
					open(line)
				end
			end
		end,
		on_stderr = function(_, lines)
			local message = table.concat(lines, "\n")
			if message:match("%S") then
				vim.notify(message, vim.log.levels.ERROR)
			end
		end,
		on_exit = function()
			if sessions[file] == session then
				sessions[file] = nil
			end
		end,
	})
	if session.job <= 0 then
		sessions[file] = nil
		vim.notify("Cannot start PDF preview; python3 is required", vim.log.levels.ERROR)
	end
end

function M.refresh(file)
	file = vim.fn.fnamemodify(file, ":p")
	if sessions[file] then
		vim.fn.chansend(sessions[file].job, "refresh\n")
	else
		start(file)
	end
end

function M.view(file)
	file = vim.fn.fnamemodify(file, ":p")
	local session = sessions[file]
	if session and session.url then
		open(session.url)
	elseif not session then
		start(file)
	end
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	group = vim.api.nvim_create_augroup("tex_preview", { clear = true }),
	callback = function()
		for _, session in pairs(sessions) do
			vim.fn.jobstop(session.job)
		end
	end,
})

return M
