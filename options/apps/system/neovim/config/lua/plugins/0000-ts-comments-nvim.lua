return {
  -- [ts-comments.nvim](https://github.com/folke/ts-comments.nvim)
  -- Better comments and override support for treesitter languages
  -- Has no external dependencies
  "ts-comments.nvim",                               -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  after = function()
    require("ts-comments").setup()                  -- Lua module path
  end,
}
