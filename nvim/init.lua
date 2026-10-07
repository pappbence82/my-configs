-- ==========================================
-- Leader (must be set before lazy)
-- ==========================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ==========================================
-- Options
-- ==========================================
local o = vim.opt
o.number = true
o.relativenumber = true
o.termguicolors = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.clipboard = "unnamedplus"
o.undofile = true
o.scrolloff = 8
o.splitright = true
o.splitbelow = true
o.cursorline = true
o.signcolumn = "yes"
o.updatetime = 250
o.timeoutlen = 400
o.mouse = "a"
o.showmode = false
o.completeopt = { "menu", "menuone", "noselect" }

-- ==========================================
-- Bootstrap lazy.nvim
-- ==========================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("Failed to clone lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================
-- Plugins
-- ==========================================
require("lazy").setup({

  -- Colorscheme
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_enable_italic = 1
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },

  -- Statusline + tabline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = { theme = "gruvbox-material" },
      tabline = { lualine_a = { "tabs" }, lualine_b = {}, lualine_c = {} },
    },
  },

  -- File tree (replaces NERDTree)
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "<C-b>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" } },
    opts = { view = { width = 32 } },
  },

  -- Fuzzy finder (replaces CtrlP)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-p>",      "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>sg", "<cmd>Telescope live_grep<CR>",  desc = "Grep (needs ripgrep)" },
      { "<leader>sb", "<cmd>Telescope buffers<CR>",    desc = "Buffers" },
      { "<leader>sh", "<cmd>Telescope help_tags<CR>",  desc = "Help" },
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "%.git[/\\]", "node_modules", "%.exe$" },
      },
    },
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "python", "cpp", "c", "javascript",
          "typescript", "tsx", "html", "css", "json", "markdown", "sql",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Indent guides (v3 API)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = { indent = { char = "│" } },
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },

  -- LSP: mason + lspconfig (replaces CoC)
  {
    "williamboman/mason.nvim",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig", "saghen/blink.cmp" },
    config = function()
      -- Give every server blink's completion capabilities
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "pyright", "ts_ls", "eslint", "jsonls", "lua_ls" },
        -- servers installed via mason are enabled automatically
      })

      vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = { border = "rounded" },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          map("n", "gd", vim.lsp.buf.definition, "Definition")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "gi", vim.lsp.buf.implementation, "Implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "Type definition")
          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "<F2>", vim.lsp.buf.rename, "Rename")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })
    end,
  },
  { "neovim/nvim-lspconfig" },

  -- Completion (replaces CoC completion + snippets)
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "none",
        ["<Tab>"]     = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"]   = { "select_prev", "snippet_backward", "fallback" },
        ["<CR>"]      = { "accept", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"]     = { "hide", "fallback" },
      },
      completion = {
        list = { selection = { preselect = false } },
        documentation = { auto_show = true },
      },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },

  -- Formatting (replaces ALE fixers + coc-prettier)
  {
    "stevearc/conform.nvim",
    keys = {
      {
        "<leader>f",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "x" },
        desc = "Format",
      },
    },
    opts = {
      formatters_by_ft = {
        python = { "autopep8" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        cpp = { "clang_format" },
        c = { "clang_format" },
      },
      format_on_save = false,
    },
  },

  -- Emmet
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "javascript", "javascriptreact" },
    init = function()
      vim.g.user_emmet_leader_key = "<C-e>"
      vim.g.user_emmet_install_global = 0
    end,
    config = function()
      vim.cmd("EmmetInstall")
    end,
  },

}, {
  checker = { enabled = false },
  rocks = { enabled = false },
})

-- ==========================================
-- Keybindings
-- ==========================================
local map = vim.keymap.set

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Tabs (leader-based so the `t` motion keeps working)
map("n", "<leader>tn", "<cmd>tabnew<CR>")
map("n", "<leader>tq", "<cmd>tabclose<CR>")
map("n", "[t", "<cmd>tabprev<CR>")
map("n", "]t", "<cmd>tabnext<CR>")

-- Diagnostics
map("n", "<leader>a", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end)
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end)

-- Exit terminal mode easily
map("t", "<Esc><Esc>", [[<C-\><C-n>]])

-- ==========================================
-- Run code (Windows)
-- ==========================================
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    map("n", "<F5>", ':w<CR>:!python "%"<CR>', { buffer = true })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function()
    -- build + run with warnings
    map("n", "<F5>", ':w<CR>:!g++ -g -Wall -Wextra "%" -o "%:r.exe" && "%:r.exe"<CR>', { buffer = true })
    -- run last build only
    map("n", "<F7>", ':!"%:r.exe"<CR>', { buffer = true })
  end,
})

-- ==========================================
-- Terminal
-- ==========================================
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd("startinsert")
  end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank() end,
})
