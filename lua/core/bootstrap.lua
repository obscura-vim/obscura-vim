local M = {}
local fn = vim.fn

M.echo = function(str)
	vim.cmd("redraw")
	vim.api.nvim_echo({ { str, "Bold" } }, true, {})
end

local function shell_call(args)
	local output = fn.system(args)
	assert(vim.v.shell_error == 0, "External call failed with error code: " .. vim.v.shell_error .. "\n" .. output)
end

M.lazy = function(install_path)
	M.echo("  Installing lazy.nvim & plugins ...")
	local repo = "https://github.com/folke/lazy.nvim.git"
	shell_call({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, install_path })
	vim.opt.rtp:prepend(install_path)
end

-- Synchronously install everything a fresh setup needs: plugins, mason
-- tools and treesitter parsers. Meant for headless bootstrap
-- (nvim --headless "+ObscuraSync" +qa), safe to re-run any time.
M.sync = function()
	M.echo("ObscuraSync: syncing plugins ...")
	require("lazy").sync({ wait = true, show = false })

	M.echo("ObscuraSync: installing mason tools ...")
	require("lazy").load({ plugins = { "mason.nvim" } })
	local registry = require("mason-registry")
	pcall(registry.refresh)

	local failed = {}
	local pending = 0
	for _, name in ipairs(vim.g.mason_binaries_list or {}) do
		local ok, pkg = pcall(registry.get_package, name)
		if ok and not pkg:is_installed() then
			pending = pending + 1
			pkg:install():once("closed", function()
				if not pkg:is_installed() then
					table.insert(failed, name)
				end
				pending = pending - 1
			end)
		elseif not ok then
			table.insert(failed, name)
		end
	end
	vim.wait(30 * 60 * 1000, function()
		return pending == 0
	end, 500)

	M.echo("ObscuraSync: installing treesitter parsers ...")
	local ts_ok, err = pcall(function()
		local parsers = require("plugins.configs.treesitter")
		require("nvim-treesitter").install(parsers):wait(30 * 60 * 1000)
	end)

	if pending > 0 then
		M.echo("ObscuraSync: timed out waiting for mason installs")
	end
	if #failed > 0 then
		M.echo("ObscuraSync: failed mason packages: " .. table.concat(failed, ", "))
	end
	if not ts_ok then
		M.echo("ObscuraSync: treesitter install failed: " .. tostring(err))
	end
	if pending == 0 and #failed == 0 and ts_ok then
		M.echo("ObscuraSync: done, everything is ready")
	end
end

return M
