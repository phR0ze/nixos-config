return {
  -- [Zen Mode](https://github.com/folke/zen-mode.nvim)
  -- Open current buffer in new full-screen floating window
  -- optionally depends on twilight.nvim which in turn depends on treesitter
  "zen-mode.nvim",                                  -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  before = function()
    require("lz.n").trigger_load("twilight.nvim")
  end,
  after = function()                                -- Function to load after the event
    require("zen-mode").setup({
      window = {
        backdrop = 0.95,
        width = 120,                                -- width of the Zen window
        height = 1,                                 -- height of the Zen window
        options = {
          number = false,                           -- disable number column
          signcolumn = "no",                        -- disable signcolumn
          relativenumber = false,                   -- disable relative numbers
          -- cursorline = false, -- disable cursorline
          -- cursorcolumn = false, -- disable cursor column
          -- foldcolumn = "0", -- disable fold column
          -- list = false, -- disable whitespace characters
        },
      },
      plugins = {
        options = {
          enabled = true,                           -- check the given options
          ruler = true,                             -- disables the ruler text in the cmd line area
          showcmd = false,                          -- disables the command in the last line of the screen
          laststatus = 0,                           -- 0 = turn off, 3 = enable the statusline in zen mode
        },
        twilight = { enabled = true },              -- enable to start Twilight when zen mode opens
        gitsigns = { enabled = false },             -- disables git signs
        --tmux = { enabled = true },                  -- disables the tmux statusline
        alacritty = {                               -- zoom alacritty terminal font to the given size
          enabled = true,
          font = "16",                              -- font size
        },
      },
      -- on_open = function()
      --   require('cmp').setup { enabled = false }
      --   vim.cmd("Copilot disable")
      -- end,
      -- on_close = function()
      --   require('cmp').setup { enabled = true }
      --   vim.cmd("Copilot enable")
      -- end,
    })
  end,
  keys = {
    { "<leader>z", "<cmd>ZenMode<cr>", desc = "ZenMode toggle" },
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
