local M = {}

local servers = {
	"html",
	"cssls",
	"tsserver",
	"clangd",
	"pyright",
	"lua_ls",
	"rust_analyzer",
	"eslint",
	"gopls",
	"sqlls",
	"texlab",
}

M.on_attach = function(client, bufnr)
	client.server_capabilities.documentFormattingProvider = false
	client.server_capabilities.documentRangeFormattingProvider = false

	client.server_capabilities.semanticTokensProvider = nil
end

M.capabilities = require("blink.cmp").get_lsp_capabilities()

local server_configs = {
	html = {
		cmd = { "vscode-html-language-server", "--stdio" },
		filetypes = { "html" },
		root_markers = { "package.json", ".git" },
		init_options = {
			provideFormatter = true,
			embeddedLanguages = { css = true, javascript = true },
			configurationSection = { "html", "css", "javascript" },
		},
	},
	cssls = {
		cmd = { "vscode-css-language-server", "--stdio" },
		filetypes = { "css", "scss", "less" },
		root_markers = { "package.json", ".git" },
		init_options = { provideFormatter = true },
		settings = { css = { validate = true }, scss = { validate = true }, less = { validate = true } },
	},
	tsserver = {
		cmd = { "typescript-language-server", "--stdio" },
		filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
		root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	},
	clangd = {
		cmd = { "clangd" },
		filetypes = { "c", "c.doxygen", "cpp", "cpp.doxygen", "objc", "objcpp", "cuda" },
		root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac", ".git" },
	},
	pyright = {
		cmd = { "pyright-langserver", "--stdio" },
		filetypes = { "python" },
		root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
	},
	lua_ls = {
		cmd = { "lua-language-server" },
		filetypes = { "lua" },
		root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
	},
	rust_analyzer = {
		cmd = { "rust-analyzer" },
		filetypes = { "rust" },
		root_markers = { "Cargo.toml", "rust-project.json", ".git" },
	},
	eslint = {
		cmd = { "vscode-eslint-language-server", "--stdio" },
		filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte", "astro", "htmlangular" },
		root_markers = { "eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.yaml", ".eslintrc.yml", ".eslintrc.json", ".git" },
	},
	gopls = {
		cmd = { "gopls" },
		filetypes = { "go", "gomod", "gowork", "gotmpl" },
		root_markers = { "go.work", "go.mod", ".git" },
	},
	sqlls = {
		cmd = { "sql-language-server", "up", "--method", "stdio" },
		filetypes = { "sql", "mysql" },
		root_markers = { ".sqllsrc.json" },
	},
	texlab = {
		cmd = { "texlab" },
		filetypes = { "tex", "cls" },
		root_markers = { ".git", ".latexmkrc", "latexmkrc", ".texlabroot", "texlabroot", "Tectonic.toml" },
	},
}

for name, config in pairs(server_configs) do
	vim.lsp.config(name, config)
end

vim.lsp.config("*", {
	on_attach = M.on_attach,
	capabilities = M.capabilities,
})

vim.diagnostic.config({
	virtual_text = false,
	signs = false,
	update_in_insert = false,
	underline = true,
	severity_sort = true,
	open_loclist = true,
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
				},
				maxPreload = 100000,
				preloadFileSize = 10000,
			},
		},
	},
})

vim.lsp.config("gopls", {
	on_attach = function(client, bufnr)
		M.on_attach(client, bufnr) -- при необходимости вызовите базовую
		vim.o.splitright = false
		vim.o.splitbelow = false
	end,
})
vim.lsp.config("pyright", {
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "on",
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "workspace",
			},
		},
	},
})

vim.lsp.config("texlab", {
	settings = {
		texlab = {
			build = {
				executable = "latexmk",
				args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
				onSave = true,
				forwardSearchAfter = false,
			},
			chktex = {
				onEdit = true,
				onOpenAndSave = true,
			},
			diagnostics = {
				delay = 300,
			},
		},
	},
	filetypes = { "tex", "cls" },
})

for _, server_name in ipairs(servers) do
	vim.lsp.enable(server_name)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	pattern = { "*.star", "i.yaml", "i.*.yaml" },
	callback = function(args)
		local root_dir = vim.fs.dirname(
			vim.fs.find({ "a.yaml", ".arcadia.root" }, { upward = true, path = args.file })[1]
		)
		if not root_dir then
			return
		end
		vim.lsp.start({
			name = "infractl",
			cmd = { "ya", "tool", "infractl", "lsp" },
			root_dir = root_dir,
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end,
			capabilities = M.capabilities,
		})
	end,
})

return M
