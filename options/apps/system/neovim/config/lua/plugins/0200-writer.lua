return {
  {
    -- [Zen Mode](https://github.com/folke/zen-mode.nvim)
    -- Open current buffer in a centered floating window for distraction-free writing
    "zen-mode.nvim", -- Lua result/pack/opt module name
    event = "DeferredUIEnter", -- Equivalent of VeryLazy
    keys = {
      { "<leader>z", "<cmd>ZenMode<cr>", desc = "ZenMode toggle" },
    },
    after = function() -- Function to load after the event
      local writing_maps = {
        -- Normal mode visual-line navigation
        { mode = "n", lhs = "j",      rhs = "gj" },
        { mode = "n", lhs = "k",      rhs = "gk" },
        { mode = "n", lhs = "0",      rhs = "g0" },
        { mode = "n", lhs = "^",      rhs = "g^" },
        { mode = "n", lhs = "$",      rhs = "g$" },
        { mode = "n", lhs = "<Down>", rhs = "gj" },
        { mode = "n", lhs = "<Up>",   rhs = "gk" },
        { mode = "n", lhs = "<Home>", rhs = "g<Home>" },
        { mode = "n", lhs = "<End>",  rhs = "g<End>" },
        -- Visual mode visual-line navigation
        { mode = "v", lhs = "j",      rhs = "gj" },
        { mode = "v", lhs = "k",      rhs = "gk" },
        { mode = "v", lhs = "0",      rhs = "g0" },
        { mode = "v", lhs = "^",      rhs = "g^" },
        { mode = "v", lhs = "$",      rhs = "g$" },
        { mode = "v", lhs = "<Down>", rhs = "gj" },
        { mode = "v", lhs = "<Up>",   rhs = "gk" },
        { mode = "v", lhs = "<Home>", rhs = "g<Home>" },
        { mode = "v", lhs = "<End>",  rhs = "g<End>" },
        -- Insert mode visual-line navigation
        { mode = "i", lhs = "<Down>", rhs = "<C-o>gj" },
        { mode = "i", lhs = "<Up>",   rhs = "<C-o>gk" },
        { mode = "i", lhs = "<Home>", rhs = "<C-o>g<Home>" },
        { mode = "i", lhs = "<End>",  rhs = "<C-o>g<End>" },
      }

      require("zen-mode").setup({
        window = {
          backdrop = 0.95,
          width = 80, -- width of the Zen window
          height = 1, -- height of the Zen window
          options = {
            number = false, -- disable number column
            signcolumn = "no", -- disable signcolumn
            relativenumber = false, -- disable relative numbers
            -- cursorline = false, -- disable cursorline
            -- cursorcolumn = false, -- disable cursor column
            -- foldcolumn = "0", -- disable fold column
            -- list = false, -- disable whitespace characters
          },
        },
        plugins = {
          options = {
            enabled = true, -- check the given options
            ruler = true, -- disables the ruler text in the cmd line area
            showcmd = false, -- disables the command in the last line of the screen
            laststatus = 0, -- 0 = turn off, 3 = enable the statusline in zen mode
          },
          gitsigns = { enabled = false }, -- disables git signs
        },
        on_open = function()
          -- Soft wrap at word boundaries
          vim.wo.wrap = true
          vim.wo.linebreak = true
          vim.wo.spell = true
          -- Disable scrolloff to prevent logical-line jumps on wrapped paragraphs
          vim.g._zen_scrolloff = vim.opt.scrolloff:get()
          vim.g._zen_smoothscroll = vim.opt.smoothscroll:get()
          vim.opt.scrolloff = 0
          vim.opt.smoothscroll = true

          -- Visual-line navigation: remap motion keys buffer-locally
          for _, m in ipairs(writing_maps) do
            vim.keymap.set(m.mode, m.lhs, m.rhs, { buffer = true, silent = true })
          end
        end,
        on_close = function()
          -- Restore wrap settings
          vim.wo.wrap = false
          vim.wo.linebreak = false
          vim.wo.spell = false
          -- Restore scrolloff and smoothscroll
          vim.opt.smoothscroll = vim.g._zen_smoothscroll or false
          vim.opt.scrolloff = vim.g._zen_scrolloff or 8

          -- Remove the buffer-local navigation remaps
          for _, m in ipairs(writing_maps) do
            pcall(vim.keymap.del, m.mode, m.lhs, { buffer = true })
          end
        end,
      })
    end,
  },
}

-- local value = 1
--
-- if vim.g.neovide then value = 0 end
--
-- vim.keymap.set("n", "<leader>zz", function()
--     require("zen-mode").setup {
--         window = {
--             backdrop = value,
--             width = 100,
--             options = { }
--         },
--     }
--     require("zen-mode").toggle()
--     vim.wo.wrap = false
--     vim.wo.number = true
--     vim.wo.rnu = true
--     ColorMyPencils()
--     disable_background()
-- end)
--
-- vim.keymap.set("n", "<leader>zZ", function()
--     require("zen-mode").setup {
--         window = {
--             backdrop = value,
--             width = 80,
--             options = { }
--         },
--     }
--     require("zen-mode").toggle()
--     vim.wo.wrap = false
--     vim.wo.number = false
--     vim.wo.rnu = false
--     vim.opt.colorcolumn = "0"
--     ColorMyPencils()
--     disable_background()
-- end)
