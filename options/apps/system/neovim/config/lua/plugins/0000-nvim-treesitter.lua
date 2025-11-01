return {
  -- Test by running :TSModuleInfo
  -- Test by running :TSUpdate
  -- [Nvim-nix guide](https://github.com/adman44532/nvim-nix)
  {
    "nvim-treesitter",
    after = function()
      require("nvim-treesitter.configs").setup({
        modules = {},
        sync_install = false,
        ignore_install = {},
        ensure_installed = {},
        auto_install = false,
        indent = {
          enable = true,
        },
        context_commentstring = {
          enable = true,
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      })
    end,
  },
  {
    "nvim-treesitter-context",
    event = "DeferredUIEnter",
    before = function()
      require("lz.n").trigger_load("nvim-treesitter")
    end,
    after = function()
      require("treesitter-context").setup({
        enable = true,
        multiwindow = false,
        max_lines = 8, -- or 3 ?
        min_window_height = 16,
        line_numbers = true,
        mode = "cursor",
      })
    end,
  },
  {
    "nvim-treesitter-textobjects",
    event = "DeferredUIEnter",
    before = function()
      require("lz.n").trigger_load("nvim-treesitter")
    end,
    after = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {},
      })
    end,
    binds = {},
  },
  -- {
  --   "nvim-treesitter",
  --   event = { "BufReadPost", "BufNewFile" },
  --   after = function()
  --     require("nvim-treesitter.configs").setup({
  --       highlight = { enable = true },
  --       indent = { enable = true },
  --       auto_install = true,
  --       ensure_installed = {
  --         "bash", "c", "cpp", "css", "go", "html", "json", "javascript", "lua", 
  --         "nix", "python", "rust", "toml", "typescript",
  --       },
  --     })
  --   end,
  -- },
  -- {
  --   "nvim-treesitter",
  --   event = "FileType",
  --   after = function()
  --     require("nvim-treesitter.configs").setup({
  --       highlight = { enable = true, additional_vim_regex_highlighting = false },
  --       ensure_installed = { "c", "lua", "rust", "nix", "toml", "yaml", "json" },
  --       auto_install = true,
  --       incremental_selection = {
  --         enable = true,
  --         keymaps = {
  --           init_selection = false,
  --           node_decremental = "<A-CR>",
  --           node_incremental = "<CR>",
  --           -- scope_incremental = "grc",
  --         },
  --       },
  --       indent = { enable = true },
  --     })
  --   end,
  -- },

  -- {
  --   "nvim-treesitter-textobjects",
  --   event = { "BufReadPre", "BufNewFile" },
  --   after = function()
  --     ---@diagnostic disable-next-line: missing-fields
  --     require("nvim-treesitter.configs").setup({
  --       ensure_installed = { "c", "lua", "rust", "nix", "toml" },
  --       auto_install = true,
  --       highlight = {
  --         enable = true,
  --       },
  --       indent = {
  --         enable = true,
  --       },
  --       textobjects = {
  --         select = {
  --           enable = true,
  --           lookahead = true,
  --
  --           keymaps = {
  --             ["af"] = "@function.outer",
  --             ["if"] = "@function.inner",
  --             ["ac"] = "@class.outer",
  --             ["ic"] = "@class.inner",
  --             ["ia"] = "@parameter.inner",
  --             ["aa"] = "@parameter.outer",
  --             ["ix"] = "@comment.inner",
  --             ["ax"] = "@comment.outer",
  --           },
  --         },
  --         swap = {
  --           enable = true,
  --           swap_next = {
  --             ["<leader>a"] = "@parameter.inner",
  --           },
  --           swap_previous = {
  --             ["<leader>A"] = "@parameter.inner",
  --           },
  --         },
  --         move = {
  --           enable = true,
  --           set_jumps = true,
  --           goto_next_start = {
  --             ["]a"] = "@parameter.inner",
  --             ["]f"] = "@function.outer",
  --           },
  --           goto_next_end = {
  --             ["]A"] = "@parameter.outer",
  --             ["]F"] = "@function.outer",
  --           },
  --           goto_previous_start = {
  --             ["[a"] = "@parameter.outer",
  --             ["[f"] = "@function.outer",
  --           },
  --           goto_previous_end = {
  --             ["[A"] = "@parameter.outer",
  --             ["[F"] = "@function.outer",
  --           },
  --         },
  --       },
  --     })
  --
  --     vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = false })
  --   end,
  -- },
}
