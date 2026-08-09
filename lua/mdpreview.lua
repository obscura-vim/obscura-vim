local api = vim.api
local preview_dir = os.getenv("HOME") .. "/.local/share/hugo-preview"
local content_dir = preview_dir .. "/content"

os.execute("mkdir -p " .. content_dir)
local preview_content = vim.fn.expand("~/.local/share/hugo-preview/content/preview.md")

local hugo_job_id = nil

local function ensure_hugo_server()
	if hugo_job_id ~= nil then
		return
	end

	hugo_job_id = vim.fn.jobstart({
		"hugo",
		"server",
		"--disableFastRender",
		"--watch",
	}, {
		cwd = preview_dir,
		detach = true,
		stdout_buffered = true,
		stderr_buffered = true,
		on_exit = function()
			hugo_job_id = nil
		end,
	})

	if hugo_job_id <= 0 then
		hugo_job_id = nil
		print("Failed to start hugo server")
	end
end
