# ObscuraVim

ObscuraVim is a compact Neovim configuration for people who prefer the editor to stay out of the way. It keeps a small, deliberate set of plugins and relies on Neovim's built-in APIs for package management, LSP, diagnostics, commenting, terminal workflows, and file navigation.

## Requirements

- Neovim 0.12+
- Git
- `rg` for project search

Language servers and formatters are managed with Mason. TeX support expects `latexmk`, a TeX distribution, Python 3.9+, Node.js 20.16+ and npm, and a modern browser. Markdown Preview also requires Node.js and npm.

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

Markdown tables render directly in Neovim with aligned cells and borders using `render-markdown.nvim`. The cursor row reveals the source for editing, and Insert mode shows raw Markdown. Use `:RenderMarkdown toggle` to switch rendering on or off. The `markdown` and `markdown_inline` Treesitter parsers are required (`:TSInstall markdown markdown_inline`).

### TeX preview

`<Space>b` (`:VimtexCompile`) starts continuous compilation. The first successful build opens a preview in your default browser. Save a TeX file with `:w` to rebuild; the existing preview updates after successful builds. Press `<Space>b` again to stop compilation. Texlab's separate build-on-save is disabled to avoid duplicate builds.

`<Space>v` (`:VimtexView`) opens the preview manually, including after closing its tab. Browser settings determine which window/profile receives the URL. Configure your preferred browser as the system default.

The preview uses PDF.js and preserves zoom, page number, and scroll position when the PDF changes. Set the zoom percentage in the toolbar, use the +/− buttons, or use Ctrl+wheel/pinch. Fit width follows the window size. If pages are removed, the view moves to the last remaining page.

The local server binds to `127.0.0.1`, serves the selected PDF and viewer assets, and stops when Neovim exits. Failed builds retain the last successful PDF. SyncTeX navigation is not supported. On first use, `npm ci` installs the locked PDF.js dependency under `scripts/pdf_preview/`; this requires internet access. Subsequent previews work offline.

Run the TeX integration check with `nvim --headless -u NONE -l tests/tex_preview.lua` (VimTeX, `latexmk`, `pdflatex`, Python 3, and `curl` required). It compiles a temporary document and intercepts browser opening.

For a configuration installed with individual symlinks, also link `autoload/`, `scripts/`, and `lua/core/tex_preview.lua` into the installed configuration. Run `NVIM_TEX_TEST_RUNTIME="$HOME/.config/nvim" nvim --headless -u NONE -l tests/tex_preview.lua` to check the installed runtime, including these links.

For the browser regression check, run `npm ci --prefix scripts/pdf_preview --ignore-scripts --omit=optional`, then `node tests/tex_preview_browser.mjs`. It uses installed Chrome on macOS; elsewhere set `CHROME_PATH` or install Playwright's Chromium. It verifies zoom and scroll retention with actual PDF recompilation.

`ndiff` shows 10 unchanged lines around each change by default. Adjust it with:

```lua
require("ndiff").setup({ context_lines = 40 })
```

In `ndiff`, selecting a file starts at the top. `,ff` / `,fF` fuzzy-search only the files in the current diff; `,fw` / `,fW` fuzzy-search its contents, including removed lines and hidden context. These shortcuts work in both the diff and file tree. Selecting a content match opens that section with its context expanded and moves to the matching line.

Run the ndiff regression checks with `nvim --headless -u NONE -l tests/ndiff.lua` (Telescope and Plenary must be installed).

## Design

The configuration is intentionally not an IDE distribution. It uses plugins where Neovim has no comparable built-in tool: fuzzy search, snippet sources, external formatting, TeX integration, Markdown preview, Git decorations, and a small set of focused editing aids. Everything else lives in ordinary Lua modules and Neovim's own APIs.
