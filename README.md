# ObscuraVim

ObscuraVim is a compact Neovim configuration for people who prefer the editor to stay out of the way. It keeps a small, deliberate set of plugins and relies on Neovim's built-in APIs for package management, LSP, diagnostics, commenting, terminal workflows, and file navigation.

## Requirements

- Neovim 0.12+
- Git
- `rg` for project search

Language servers and formatters are managed with Mason. TeX support expects `latexmk`, `nvr`, and Zathura. Markdown Preview requires Node.js and npm.

## Installation

```sh
mv ~/.config/nvim ~/.config/nvim.bak
git clone https://github.com/obscura-vim/obscura-vim.git ~/.config/nvim
nvim
```

On first start, Neovim installs the pinned plugin set with `vim.pack`. Restart after installation. Update plugins with `:PackUpdate`; use `:Mason` to install or update language tools, `:TSInstall` for initial Treesitter parsers, and `:TSUpdate` for parser updates.

Markdown Preview has an upstream npm dependency. Install it from the plugin's `app` directory after the first startup if you use `:MarkdownPreview`.

## Workflow

Leader is `Space`.

- `,ff`, `,fw` — find files and grep with Telescope
- `<Tab>` — switch buffers
- `<C-e>` — toggle netrw
- `s` — jump with Flash
- `gq` — format
- `gd`, `K`, `E` — definition, hover, diagnostic
- `gcc` / `gc`, or `,c` — built-in commenting
- `<leader>b`, `<leader>v` — build and view TeX documents

The complete keymap is in `lua/core/mappings.lua`.

## Design

The configuration is intentionally not an IDE distribution. It uses plugins where Neovim has no comparable built-in tool: fuzzy search, snippet sources, external formatting, TeX integration, Markdown preview, Git decorations, and a small set of focused editing aids. Everything else lives in ordinary Lua modules and Neovim's own APIs.
