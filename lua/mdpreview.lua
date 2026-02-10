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

local function sync_markdown_to_preview()
	local buf = api.nvim_get_current_buf()
	local path = api.nvim_buf_get_name(buf)
	if path == "" then
		return
	end

	local lines = api.nvim_buf_get_lines(buf, 0, -1, false)

	vim.fn.mkdir(vim.fn.fnamemodify(preview_content, ":h"), "p")
	vim.fn.writefile(lines, preview_content)
end

local function markdown_preview()
	ensure_hugo_server()
	sync_markdown_to_preview()
	local file_path = api.nvim_buf_get_name(0)
	if file_path == "" then
		return print("No file detected")
	end

	local tmp_file = content_dir .. "/preview.md"
	os.execute("cp " .. file_path .. " " .. tmp_file)
	local url = "http://localhost:1313/preview/"
	vim.cmd("silent !google-chrome-stable --new-window --app=" .. url)
end

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.md",
	callback = sync_markdown_to_preview,
})

api.nvim_create_user_command("MarkdownPreview", markdown_preview, {})
