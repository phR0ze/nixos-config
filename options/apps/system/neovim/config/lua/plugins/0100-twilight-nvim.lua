return {
  -- Twilight is a Lua plugin for Neovim 0.5 that dims inactive portions of the code you're editing.
  -- Zen-mode will automatically activate Twilight as needed
  -- depends on treesitter
  "twilight.nvim",                                  -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  before = function()
    require("lz.n").trigger_load("nvim-treesitter")
  end,
  after = function()
    require("twilight").setup({                   -- Lua module path
      treesitter = true,                          -- use treesitter for filetype
      context = 10,                               -- number of lines to show around the current line
      exclude = {},                               -- exclude these filetypes
      dimming = {
        alpha = 0.25,                             -- amount of dimming
        color = { "Normal", "#ffffff" },          -- try to get the foreground from the highlight groups or fallback color
        term_bg = "#000000",                      -- if guibg=NONE, this will be used to calculate text color
        inactive = false,                         -- when true, other windows will be fully dimmed (unless they contain the same buffer)
      },
    })
  end,
}
