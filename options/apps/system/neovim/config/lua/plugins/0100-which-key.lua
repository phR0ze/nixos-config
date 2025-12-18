return {
  -- Pops up a window that shows keymaps as you are typing
  -- Triggered by pressing your leader key
  -- depends on mini.icons
  "which-key.nvim",                                 -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  before = function()
    require("lz.n").trigger_load("mini.icons")
  end,
  after = function()                                -- Function to load after the event
    require("which-key").setup({                    -- First lazy load by plugin name not Nix package name
      preset = "modern",                            -- Window layout [ classic | modern | helix ]
      delay = 300,                                  -- Long enough delay that you don't have to see popup
    })
  end,
  keys = {
    { "<leader>?", function()
      require("which-key").show({ global = false })
    end, desc = "Keymaps Local Context", },
  },
}
