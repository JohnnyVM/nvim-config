vim.o.conceallevel = 0

local vim = vim
local Plug = vim.fn['plug#']

vim.fn['plug#begin']('~/.vim/plugged')

-- Colorscheme
Plug 'ellisonleao/gruvbox.nvim'

-- TagBar
Plug 'preservim/tagbar'

Plug 'ludovicchabant/vim-gutentags'

-- search
-- ctrlp
-- Plug 'ctrlpvim/ctrlp.vim'
Plug('junegunn/fzf', { ['do'] = vim.fn['fzf#install()'] })
Plug 'junegunn/fzf.vim'

-- Tree-sitter
Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate' })

-- Document generator
Plug('kkoomen/vim-doge', { ['do'] = vim.fn['doge#install'] })

Plug 'mechatroner/rainbow_csv'
Plug('fatih/vim-go', { ['do'] = vim.fn['GoUpdateBinaries'] })
Plug 'rust-lang/rust.vim'
Plug 'bling/vim-bufferline'
Plug 'will133/vim-dirdiff'
Plug 'tpope/vim-fugitive'

-- AI
--Plug 'github/copilot.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'olimorris/codecompanion.nvim'

-- LSP definitions (still required)
Plug 'neovim/nvim-lspconfig'

-- Autocomplete
Plug "hrsh7th/nvim-cmp"
Plug "hrsh7th/cmp-nvim-lsp"

vim.fn['plug#end']()

vim.g.copilot_enabled = 0

require("codecompanion").setup({
  strategies = {
    chat = {
      adapter = "opencode",
    },
    inline = {
      adapter = "opencode",
    },
  },
  adapters = {
    opencode = function()
      return require("codecompanion.adapters").extend("openai_compatible", {
        name = "opencode",
      })
    end,
  },
})

-- vim-go
vim.g.go_def_mode='gopls'
vim.g.go_info_mode='gopls'

vim.keymap.set("n", "<C-f>", function()
  vim.cmd("Rg")
end, { noremap = true, silent = true })
vim.keymap.set("n", "<C-t>", function()
  if vim.bo.buftype ~= "terminal" then
    vim.cmd("Tags")
  end
end, { noremap = true, silent = true })
vim.keymap.set("n", "<C-b>", function()
  -- Dump terminal buffer contents to temp files so the fzf preview can read them.
  -- Also write a lookup file: <term-name> TAB <bufnr>
  local lookup = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.buflisted(bufnr) == 1 and vim.bo[bufnr].buftype == "terminal" then
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      while #lines > 0 and lines[#lines] == "" do table.remove(lines) end
      vim.fn.writefile(lines, "/tmp/nvim_term_buf_" .. bufnr)
      local name = vim.api.nvim_buf_get_name(bufnr)
      table.insert(lookup, name .. "\t" .. bufnr)
    end
  end
  vim.fn.writefile(lookup, "/tmp/nvim_term_lookup")

  local preview_script = vim.fn.expand("~/.vim/plugged/fzf.vim/bin/preview.sh")
  -- {1} is the target field (file path or term:// URI, possibly with :linenum suffix).
  -- Strip the trailing :digits to recover the buffer name, look it up, then cat the dump.
  local preview_cmd = table.concat({
    "target={1};",
    "if [[ \"$target\" == term://* ]]; then",
    "  base=$(echo \"$target\" | sed 's/:[0-9]*$//');",
    "  bufnr=$(grep -F \"$base\" /tmp/nvim_term_lookup 2>/dev/null | cut -f2 | head -1);",
    "  [[ -n \"$bufnr\" ]] && tail -\"$FZF_PREVIEW_LINES\" /tmp/nvim_term_buf_\"$bufnr\"",
    "    || echo '[Terminal buffer content unavailable]';",
    "elif [[ -z \"$target\" ]]; then",
    "  echo '[No Name buffer]';",
    "else",
    "  bash " .. preview_script .. " \"$target\";",
    "fi",
  }, " ")

  vim.fn["fzf#vim#buffers"]("", {
    placeholder = "{1}",
    options = { "--preview", preview_cmd },
  }, 0)
end, { noremap = true, silent = true })
vim.keymap.set("n", "<C-p>", function()
  if vim.bo.buftype == "terminal" then return end
  vim.fn["fzf#vim#files"]("", { options = { "--delimiter=/", "--with-nth=-1" } }, 0)
end, { silent = true })

--vim.g.ctrlp_working_path_mode = 'ra'
--vim.g.ctrlp_cache_dir = '~/.cache/ctrlp'
--vim.g.ctrlp_extensions = {'tag'}
--vim.g.ctrlp_user_command = {'.git', 'cd %s && git ls-files -co --exclude-standard'}
--vim.g.ctrlp_custom_ignore = {
--  dir = [[\v(node_modules|\.git|dist|build|\.cache)$]],
--  file = [[\v\.(o|so|dll|pyc|lock|sum)$]],
--  link = 0,
--}
--vim.g.gutentags_ctags_exclude = {
--  "node_modules",
--  ".git",
--  "dist",
--  "build",
--  "target",
--  ".cache",
--}
--vim.g.gutentags_ctags_extra_args = {
--  "--exclude=node_modules",
--  "--exclude=.git",
--  "--exclude=dist",
--  "--exclude=build",
--  "--exclude=target",
--  "--exclude=.cache",
--}

vim.opt.number = true
vim.g.netrw_keepdir = 1
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4

------------------------------------------------------------
-- Terminal mode
------------------------------------------------------------
-- Double Esc: exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
  buffer = buf,
  noremap = true,
  silent = true,
})

------------------------------------------------------------
-- Normal mode
------------------------------------------------------------
vim.keymap.set("n", "<F7>", function()
  vim.cmd("Lexplore")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.1))
end, { noremap = true, silent = true })
-- TODO open it to the left
vim.keymap.set("n", "<F8>", function()
  vim.cmd("TagbarToggle")
end, { noremap = true, silent = true })
------------------------------------------------------------
-- LSP keymaps & diagnostics
------------------------------------------------------------
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { buffer = bufnr })
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { buffer = bufnr })
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { buffer = bufnr })
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { buffer = bufnr })

    if client.server_capabilities.hoverProvider then
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
    end
    if client.server_capabilities.formatProvider then
      vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { buffer = bufnr })
    end
    if client.server_capabilities.renameProvider then
      vim.keymap.set('n', '<leader>cn', vim.lsp.buf.rename, { buffer = bufnr })
    end
    if client.server_capabilities.codeActionProvider then
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr })
    end
    if client.server_capabilities.referencesProvider then
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr })
    end
  end,
})

vim.api.nvim_create_user_command("Rename", function()
  vim.lsp.buf.rename()
end, { buffer = bufnr })

-- Buffer navigation with Alt+h / Alt+l
vim.keymap.set("n", "<M-h>", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<M-l>", ":bnext<CR>", { desc = "Next buffer" })

vim.opt.tabstop = 4      -- how wide a <Tab> looks
vim.opt.shiftwidth = 4  -- how wide auto-indent is
vim.opt.softtabstop = 4 -- how many spaces <Tab> feels like

require("trans")

--require("SaveBuffPath")
--vim.api.nvim_set_keymap('n', '<leader>yp', ':SavePath<CR>:UsePath<CR>', { noremap = true, silent = true })
------------------------------------------------------------
-- LSP (NEW API)
------------------------------------------------------------
local capabilities = vim.lsp.protocol.make_client_capabilities()

-- If you use nvim-cmp (recommended), advertise completion capabilities to servers:
local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
if ok then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

vim.o.completeopt = "menu,menuone,noselect"

local cmp = require("cmp")
cmp.setup({
  mapping = {
	["<C-e>"] = cmp.mapping.abort(),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  },
  sources = {
    { name = "nvim_lsp" },
  },
})

-- yaml
vim.lsp.config("yamlls", { capabilities = capabilities })
vim.lsp.enable("yamlls")
-- bash
vim.lsp.config("bashls", { capabilities = capabilities })
vim.lsp.enable("bashls")

-- python
vim.lsp.config("pylsp", {
  capabilities = capabilities,
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = {
          ignore = { "W391" },
          maxLineLength = 100,
        },
      },
    },
  },
})
vim.lsp.enable("pylsp")

-- eslint
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.js',
  callback = function()
    local buffer_path = vim.fn.expand('%:p')
    local command = string.format('npm run lint -- %s --fix', buffer_path)

    local output = vim.fn.system(command)

    if vim.v.shell_error ~= 0 then
      vim.notify(
        "ESLint fix failed:\n" .. output,
        vim.log.levels.ERROR
      )
    end
  end
})
vim.lsp.enable("eslint")

-- rust
vim.lsp.config("rust_analyzer", { capabilities = capabilities })
vim.lsp.enable("rust_analyzer")

-- go
vim.lsp.config("gopls", {
  capabilities = capabilities,
  settings = {
    gopls = {
      staticcheck = true,
      usePlaceholders = true,
    },
  },
})
vim.lsp.enable("gopls")

------------------------------------------------------------
-- Tree-sitter
------------------------------------------------------------
local ok, ts_config = pcall(require, "nvim-treesitter.config")
ts_config.setup({
  highlight = { enable = true },
  indent = { enable = true },
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "python", "go", "javascript", "typescript", "markdown" },
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.opt.foldlevel = 99
    end
  end,
})

------------------------------------------------------------
-- Markdown spell
------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "gitcommit" },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "en_us" }
  end,
})

------------------------------------------------------------
-- Colorscheme
------------------------------------------------------------
vim.cmd([[colorscheme gruvbox]])

