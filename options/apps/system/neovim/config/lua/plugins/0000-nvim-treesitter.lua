return {
  -- [Nvim-nix guide](https://github.com/adman44532/nvim-nix)
  -- modern, faster more accurate syntax highlighting and code traversal
  {
    "nvim-treesitter",
    after = function()
      require("nvim-treesitter.configs").setup({
        auto_install = false,                         -- manage parser installs with Nix
        sync_install = false,                         -- manage parser installs with Nix
        context_commentstring = {
          enable = true,
        },
        indent = {
          enable = true,
          --disable = { "yaml" },                       -- disable for yaml b/c doesn't work well
        },
        highlight = {
          enable = true,                              -- enable treesitter highlighting
          additional_vim_regex_highlighting = false,  -- disable default regex highlighting
        },

        -- incremental selection allows you to select code blocks in an expanding or contracting way 
        -- with hot keys to quickly select code blocks.
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<Enter>",
            node_incremental = "<Enter>",
            scope_incremental = false,
            node_decremental = "<Backspace>",
          },
        },
      })
    end,
  },

  -- TreeSitter context provides a context line at the top of your editor that shows the surrounding 
  -- code object e.g. function definition if your in the function and scrolling off the window.
  {
    "nvim-treesitter-context",
    event = "DeferredUIEnter",
    before = function()
      require("lz.n").trigger_load("nvim-treesitter")
    end,
    after = function()
      require("treesitter-context").setup({
        enable = true,                                -- enable this plugin
        multiwindow = false,                          -- disable multi-window support
        max_lines = 3,                                -- how many lines the window should span
        min_window_height = 16,                       -- minimum window height required to use context
        line_numbers = true,                          -- rewrite the line numbers to reflect the correct lines
        mode = "cursor",                              -- calculate context based on cusor location
      })
    end,
  },

  -- TreeSitter TextObjects
  {
    "nvim-treesitter-textobjects",
    event = "DeferredUIEnter",
    before = function()
      require("lz.n").trigger_load("nvim-treesitter")
    end,
    after = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {

          -- define text object selection keymaps and behavior
          select = {
            enable = true,
            lookahead = true,

            -- Select code. You must be in visual mode before these take affect
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["ia"] = "@parameter.inner",
              ["aa"] = "@parameter.outer",
              ["ix"] = "@comment.inner",
              ["ax"] = "@comment.outer",
            },
          },

          -- define code swap
          swap = {
            enable = true,
            swap_next = { ["<leader>a"] = "@parameter.inner", },
            swap_previous = { ["<leader>A"] = "@parameter.inner", },
          },

          -- define code navigation hot keys
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
            goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
            goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
          },
        },
      })
      vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = false })
    end,
  },
}
