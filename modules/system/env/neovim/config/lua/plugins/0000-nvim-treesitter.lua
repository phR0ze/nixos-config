return {
  -- -----------------------------------------------------------------------------------------------
  -- [Nvim-nix guide](https://github.com/adman44532/nvim-nix)
  -- modern, faster more accurate syntax highlighting and code traversal
  --
  -- nvim-treesitter 0.10.x removed the old `nvim-treesitter.configs` module entirely.
  -- Highlighting is now enabled via vim.treesitter.start() per buffer (FileType autocmd).
  -- The configs.setup() API no longer exists; use require("nvim-treesitter").setup() only for
  -- setting a custom install_dir if needed. All other features (indent, textobjects) are
  -- configured separately via their own modules.
  -- -----------------------------------------------------------------------------------------------
  {
    "nvim-treesitter",
    -- event registration ensures lz.n runs the after hook (setup call) at DeferredUIEnter.
    -- dependent plugins use vim.cmd("packadd nvim-treesitter") directly in their before hooks
    -- to guarantee it's in the runtimepath before their own plugin/*.vim files are sourced.
    event = "DeferredUIEnter",
    priority = 100,                               -- load before dependents (default is 50)
    after = function()
      -- Enable treesitter highlighting for every buffer that has a parser available.
      -- vim.treesitter.start() is idempotent and silently skips unsupported filetypes.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim-treesitter-highlight", { clear = true }),
        callback = function(ev)
          pcall(vim.treesitter.start, ev.buf)
        end,
      })
      -- Also enable for whichever buffer is open right now (if any)
      pcall(vim.treesitter.start, 0)

      -- Enable treesitter-based indentation via nvim-treesitter's indentexpr,
      -- but skip yaml where it doesn't behave well.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim-treesitter-indent", { clear = true }),
        pattern = "*",
        callback = function(ev)
          local ft = vim.bo[ev.buf].filetype
          if ft ~= "yaml" then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- -----------------------------------------------------------------------------------------------
  -- TreeSitter context provides a context line at the top of your editor that shows the surrounding 
  -- code object e.g. function definition if your in the function and scrolling off the window.
  -- -----------------------------------------------------------------------------------------------
  {
    "nvim-treesitter-context",
    event = "DeferredUIEnter",
    before = function()
      vim.cmd("packadd nvim-treesitter") -- direct packadd bypasses lz.n state during event processing
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

  -- -----------------------------------------------------------------------------------------------
  -- TreeSitter TextObjects (nvim-treesitter 0.10.x compatible API)
  -- The old nvim-treesitter.configs.setup({ textobjects = {...} }) is gone.
  -- Keymaps are registered via vim.keymap.set calling into the textobjects sub-modules directly.
  -- -----------------------------------------------------------------------------------------------
  {
    "nvim-treesitter-textobjects",
    event = "DeferredUIEnter",
    before = function()
      vim.cmd("packadd nvim-treesitter") -- direct packadd bypasses lz.n state during event processing
    end,
    after = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,                           -- jump forward to textobj automatically
        },
        move = {
          set_jumps = true,                           -- add navigation to the jumplist
        },
      })

      local sel = require("nvim-treesitter-textobjects.select")
      local swap = require("nvim-treesitter-textobjects.swap")
      local move = require("nvim-treesitter-textobjects.move")

      -- Select text objects (visual / operator-pending mode)
      vim.keymap.set({ "x", "o" }, "af", function() sel.select_textobject("@function.outer", "textobjects") end, { desc = "outer function" })
      vim.keymap.set({ "x", "o" }, "if", function() sel.select_textobject("@function.inner", "textobjects") end, { desc = "inner function" })
      vim.keymap.set({ "x", "o" }, "ac", function() sel.select_textobject("@class.outer",    "textobjects") end, { desc = "outer class" })
      vim.keymap.set({ "x", "o" }, "ic", function() sel.select_textobject("@class.inner",    "textobjects") end, { desc = "inner class" })
      vim.keymap.set({ "x", "o" }, "aa", function() sel.select_textobject("@parameter.outer","textobjects") end, { desc = "outer parameter" })
      vim.keymap.set({ "x", "o" }, "ia", function() sel.select_textobject("@parameter.inner","textobjects") end, { desc = "inner parameter" })
      vim.keymap.set({ "x", "o" }, "ax", function() sel.select_textobject("@comment.outer",  "textobjects") end, { desc = "outer comment" })
      vim.keymap.set({ "x", "o" }, "ix", function() sel.select_textobject("@comment.inner",  "textobjects") end, { desc = "inner comment" })

      -- Swap parameters
      vim.keymap.set("n", "<leader>a", function() swap.swap_next("@parameter.inner")     end, { desc = "Swap next parameter" })
      vim.keymap.set("n", "<leader>A", function() swap.swap_previous("@parameter.inner") end, { desc = "Swap previous parameter" })

      -- Navigate to next/prev function
      vim.keymap.set({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer",     "textobjects") end, { desc = "Next function start" })
      vim.keymap.set({ "n", "x", "o" }, "]F", function() move.goto_next_end("@function.outer",       "textobjects") end, { desc = "Next function end" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function start" })
      vim.keymap.set({ "n", "x", "o" }, "[F", function() move.goto_previous_end("@function.outer",   "textobjects") end, { desc = "Prev function end" })

      -- Navigate to next/prev class
      vim.keymap.set({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer",     "textobjects") end, { desc = "Next class start" })
      vim.keymap.set({ "n", "x", "o" }, "]C", function() move.goto_next_end("@class.outer",       "textobjects") end, { desc = "Next class end" })
      vim.keymap.set({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class start" })
      vim.keymap.set({ "n", "x", "o" }, "[C", function() move.goto_previous_end("@class.outer",   "textobjects") end, { desc = "Prev class end" })

      -- Navigate to next/prev parameter
      vim.keymap.set({ "n", "x", "o" }, "]a", function() move.goto_next_start("@parameter.inner",     "textobjects") end, { desc = "Next parameter start" })
      vim.keymap.set({ "n", "x", "o" }, "]A", function() move.goto_next_end("@parameter.inner",       "textobjects") end, { desc = "Next parameter end" })
      vim.keymap.set({ "n", "x", "o" }, "[a", function() move.goto_previous_start("@parameter.inner", "textobjects") end, { desc = "Prev parameter start" })
      vim.keymap.set({ "n", "x", "o" }, "[A", function() move.goto_previous_end("@parameter.inner",   "textobjects") end, { desc = "Prev parameter end" })

      vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = false })
    end,
  },
}
