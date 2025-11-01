return {
  -- [ts-comments.nvim](https://github.com/folke/ts-comments.nvim)
  -- better comments and override support for treesitter languages
  -- using LazyVim configuration as is
  -- no external dependencies
  "ts-comments.nvim",                               -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  after = function()
    require("ts-comments").setup()                  -- Lua module path
  end,
}
