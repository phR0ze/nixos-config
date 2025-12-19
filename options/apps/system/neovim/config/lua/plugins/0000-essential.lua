return {
  {
    -- ---------------------------------------------------------------------------------------------
    -- [catppuccin/nvim](https://github.com/catppuccin/nvim)
    -- Soothing pastel color scheme
    -- ---------------------------------------------------------------------------------------------
    "catppuccin-nvim",                                -- Lua result/pack/nvim-custom/opt module name
    lazy = false,                                     -- Make it immediately available
    after = function()
      require("catppuccin")
    end,
  },
  -- Doesn't handle variable highlighting and isn't a lua plugin
  -- {
  --   -- [Deus.nvim](https://github.com/tandy1229/deus.nvim)
  --   -- Non-lua Gruvbox inspired soothing color scheme
  --   "vim-deus",                                       -- Lua result/pack/nvim-custom/opt module name
  --   event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  --   after = function()
  --     require("lz.n").load("deus")
  --   end,
  -- },
  {
    -- ---------------------------------------------------------------------------------------------
    -- [gruvbox](https://github.com/ellisonleao/gruvbox.nvim)
    -- Lua port of the most famous vim colorscheme
    -- ---------------------------------------------------------------------------------------------
    "gruvbox.nvim",                                   -- Lua result/pack/nvim-custom/opt module name
    event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
    after = function()
      require("gruvbox").setup({})
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- [tokyonight.nvim](https://github.com/tolke/tokyonight.nvim)
    -- A clean, dark Neovim theme written in Lua with support for LSP, treesitter and other plugins
    -- no external dependencies
    -- ---------------------------------------------------------------------------------------------
    "tokyonight.nvim",                                -- Lua result/pack/nvim-custom/opt module name
    lazy = false,                                     -- Make it immediately available
    after = function()
      require("tokyonight").setup({})
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- [mini.icons](https://github.com/nvim-mini/mini.icons)
    -- Modern, minimal, pure lua replacement for nvim-web-devicons
    -- Can patch itself into plugins expecting nvim-web-devicons thus eliminating the need for both
    -- Using LazyVim configuration as is
    -- no external dependencies
    -- ---------------------------------------------------------------------------------------------
    "mini.icons",                                     -- Lua result/pack/nvim-custom/opt module name
    event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
    after = function()
      require("mini.icons").setup({                   -- Lua module path
        file = {
          [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
          ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
        },
        filetype = {
          dotenv = { glyph = "", hl = "MiniIconsYellow" },
        },
      })
      require("mini.icons").mock_nvim_web_devicons()  -- Setup compatibility layer for older plugins
      require('nvim-web-devicons')                    -- Load mini.pairs compatibility layer
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- Automatically inserts a matching closing character when you type an opening character like ", [, or (
    -- and does so intelligently with context awareness unlike the LazyVim choice of mini.pairs which 
    -- does it no matter what without context awareness
    -- ---------------------------------------------------------------------------------------------
    "nvim-autopairs",                                 -- Lua result/pack/opt module name
    event = "InsertEnter",                            -- Equivalent of VeryLazy
    after = function()
      require("nvim-autopairs").setup()               -- Lua module path
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- Persistence is a simple lua plugin for automated session management.
    -- saves active session under ~/.local/state/nvim/sessions on exit
    -- using the LazyVim configuration as is
    -- no external dependencies
    -- ---------------------------------------------------------------------------------------------
    "persistence.nvim",
    event = "BufReadPre",
    after = function()
      require("persistence").setup()
    end,
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>qS", function() require("persistence").select() end,desc = "Select Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- [ts-comments.nvim](https://github.com/folke/ts-comments.nvim)
    -- better comments and override support for treesitter languages
    -- using LazyVim configuration as is
    -- no external dependencies
    -- ---------------------------------------------------------------------------------------------
    "ts-comments.nvim",                               -- Lua result/pack/opt module name
    event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
    after = function()
      require("ts-comments").setup()                  -- Lua module path
    end,
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
    -- A snazy pure lua buffer line
    -- depends on mini.icons
    -- ---------------------------------------------------------------------------------------------
    "bufferline.nvim",                                -- Lua result/pack/opt module name
    event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
    before = function()
      require("lz.n").trigger_load("mini.icons")
    end,
    after = function()                                -- Function to load after the event
      require("bufferline").setup()
    end,
    keys = {
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    },
  },
  {
    -- ---------------------------------------------------------------------------------------------
    -- Blazing fast neovim statusline written in pure lua
    -- depends on mini.icons
    -- ---------------------------------------------------------------------------------------------
    "lualine.nvim",                                   -- Lua result/pack/opt module name
    event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
    before = function()
      require("lz.n").trigger_load("mini.icons")
    end,
    after = function()                                -- Function to load after the event
      require("lualine").setup({
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { { 'filename', path = 2, shorting_rule = 'minimal' } },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { 'filename', path = 2, shorting_rule = 'minimal' } },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {}
        },
      })
    end,
  }
}
