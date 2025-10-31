return {
  -- Automatically inserts a matching closing character when you type an opening character like ", [, or (
  -- and does so intelligently with context awareness unlike the LazyVim choice of mini.pairs which 
  -- does it no matter what without context awareness
  "nvim-autopairs",                                 -- Lua result/pack/opt module name
  event = "InsertEnter",                            -- Equivalent of VeryLazy
  after = function()
    require("nvim-autopairs").setup()               -- Lua module path
  end,
}
