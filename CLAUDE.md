# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration using **vim-plug** as the plugin manager. The main config is `init.lua` with custom Lua modules in `lua/`.

## Architecture

### Entry Point

`init.lua` is the single main config file. It contains vim-plug plugin declarations, all keybindings, LSP setup, and treesitter config.

### Custom Lua Modules (`lua/`)

- **`lua/trans/`** — `:Trans` command that translates text to English via the LibreTranslate API (curl POST). Supports a visual range or an inline argument.

### Plugin Categories

| Category | Plugins |
|---|---|
| Color scheme | `gruvbox.nvim` |
| Fuzzy finding | `fzf`, `fzf.vim` |
| Tags | `tagbar`, `vim-gutentags` |
| Treesitter | `nvim-treesitter` (lua, python, go, js, ts, markdown) |
| LSP | `nvim-lspconfig` + `nvim-cmp` / `cmp-nvim-lsp` |
| Language | `vim-go`, `rust.vim`, `rainbow_csv` |

### LSP Servers Configured

`yamlls`, `bashls`, `pylsp`, `eslint`, `rust_analyzer`, `gopls`

## Key Bindings Reference

| Key | Action |
|---|---|
| `<C-p>` | FZF files |
| `<C-b>` | FZF buffers |
| `<C-f>` | Ripgrep search |
| `<C-t>` | FZF tags |
| `<M-h>` / `<M-l>` | Prev / next buffer |
| `<F7>` | Toggle file explorer (netrw) |
| `<F8>` | Toggle tagbar |
| `K` | LSP hover |
| `<leader>cn` | LSP rename |
| `<leader>ca` | LSP code action |
| `gr` | LSP references |
| `[d` / `]d` | Prev / next diagnostic |
