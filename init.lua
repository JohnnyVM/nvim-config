vim.o.conceallevel = 0

local vim = vim
local Plug = vim.fn['plug#']

vim.fn['plug#begin']('~/.vim/plugged')

-- Colorscheme
Plug 'ellisonleao/gruvbox.nvim'

-- TagBar
Plug 'preservim/tagbar'

-- ctrlp
Plug 'ctrlpvim/ctrlp.vim'
Plug 'ludovicchabant/vim-gutentags'

-- Tree-sitter
Plug('nvim-treesitter/nvim-treesitter', { ['do'] = ':TSUpdate' })

-- Document generator
Plug('kkoomen/vim-doge', { ['do'] = vim.fn['doge#install'] })

Plug 'mechatroner/rainbow_csv'
Plug('fatih/vim-go', { ['do'] = vim.fn['GoUpdateBinaries'] })
Plug 'rust-lang/rust.vim'
Plug 'sbdchd/neoformat'
Plug 'bling/vim-bufferline'
Plug 'will133/vim-dirdiff'

-- AI
--Plug 'github/copilot.vim'

-- LSP definitions (still required)
Plug 'neovim/nvim-lspconfig'

-- Autocomplete
Plug "hrsh7th/nvim-cmp"
Plug "hrsh7th/cmp-nvim-lsp"

-- opencode
Plug "folke/snacks.nvim"
Plug 'NickvanDyke/opencode.nvim'

vim.fn['plug#end']()

vim.g.copilot_enabled = 0

vim.g.ctrlp_working_path_mode = 'ra'
vim.g.ctrlp_cache_dir = '~/.cache/ctrlp'
vim.g.ctrlp_extensions = {'tag', 'buffertag'}
vim.g.ctrlp_user_command = {'.git', 'cd %s && git ls-files -co --exclude-standard'}
vim.g.ctrlp_custom_ignore = {
  dir = [[\v(node_modules|\.git|dist|build|\.cache)$]],
  file = [[\v\.(o|so|dll|pyc|lock|sum)$]],
  link = 0,
}
vim.g.gutentags_ctags_exclude = {
  "node_modules",
  ".git",
  "dist",
  "build",
  "target",
  ".cache",
}
vim.g.gutentags_ctags_extra_args = {
  "--exclude=node_modules",
  "--exclude=.git",
  "--exclude=dist",
  "--exclude=build",
  "--exclude=target",
  "--exclude=.cache",
}

vim.opt.number = true
vim.g.netrw_keepdir = 1
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 4

-- Required for `opts.events.reload`
vim.o.autoread = true

------------------------------------------------------------
-- Opencode
------------------------------------------------------------
require('snacks').setup({
    input = { enabled = true },
    picker = { enabled = true },
})
-- Your configuration, if any — see `lua/opencode/config.lua`
vim.g.opencode_opts = {
  provider = {
    enabled = "terminal"
  }
}

-- Keymaps (same as your snippet)
vim.keymap.set({ "n", "x" }, "<C-a>", function()
  require("opencode").ask("@this: ", { submit = true })
end, { desc = "Ask opencode" })

vim.keymap.set({ "n", "x" }, "<C-x>", function()
  require("opencode").select()
end, { desc = "Execute opencode action…" })

vim.keymap.set({ "n", "x" }, "go", function()
  return require("opencode").operator("@this ")
end, { expr = true, desc = "Add range to opencode" })

vim.keymap.set("n", "goo", function()
  return require("opencode").operator("@this ") .. "_"
end, { expr = true, desc = "Add line to opencode" })

vim.keymap.set("n", "<S-C-u>", function()
  require("opencode").command("session.half.page.up")
end, { desc = "opencode half page up" })

vim.keymap.set("n", "<S-C-d>", function()
  require("opencode").command("session.half.page.down")
end, { desc = "opencode half page down" })
		
vim.keymap.set({ "n", "t" }, "<C-.>", function()
  require("opencode").toggle()
end, { desc = "Toggle opencode" })
	  
---- Keep these ONLY if you really want <C-a>/<C-x> for opencode,
---- because they override increment/decrement muscle memory.
--vim.keymap.set("n", "+", "<C-a>", { desc = "Increment", noremap = true })
--vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement", noremap = true })

-- Double Esc: exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
  buffer = buf,
  noremap = true,
  silent = true,
})
------------------------------------------------------------
-- Terminal mode
------------------------------------------------------------
-- Handle `opencode` events
vim.api.nvim_create_autocmd("User", {
  pattern = "OpencodeEvent:*", -- Optionally filter event types
  callback = function(args)
    ---@type opencode.cli.client.Event
    local event = args.data.event
    ---@type number
    local port = args.data.port

    -- See the available event types and their properties
    -- vim.notify(vim.inspect(event))
    -- Do something useful
    if event.type == "session.idle" then
      vim.notify("`opencode` finished responding")
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(args)
    local buf = args.buf
    local name = vim.api.nvim_buf_get_name(buf)

    if name:match("opencode") then
      -- Single Esc: send Esc to the terminal
		vim.keymap.set("t", "<Esc>", "<Esc>", {
		  buffer = buf,
		  noremap = true,
		  silent = true,
		})

    end
  end,
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

require("FindUtils")
require("trans")
-- Abre ":" con :FindAll ya escrito y espera tu entrada
vim.keymap.set("n", "<C-f>", function()
  local keys = vim.api.nvim_replace_termcodes(":FindBuf ", true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Prefill :FindBuf and wait for input" })

require("SaveBuffPath")
vim.api.nvim_set_keymap('n', '<leader>yp', ':SavePath<CR>:UsePath<CR>', { noremap = true, silent = true })
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
-- Formatting
------------------------------------------------------------
vim.g.neoformat_try_node_exe = 1
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  command = "NeoFormat prettier",
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

