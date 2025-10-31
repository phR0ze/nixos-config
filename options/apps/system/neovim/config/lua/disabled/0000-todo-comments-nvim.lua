return {
  -- [todo-comments.nvim](https://github.com/folke/todo-comments.nvim)
  -- Highlight, list and search todo comments in your projects 
  -- Has no external dependencies
  -- Depends on: ripgrep, plenary.nvim
  -- Optionally depends on: Trouble, Telescope, FzfLua
  "todo-comments.nvim",                             -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  after = function()
    require("flash.nvim").setup()                   -- Lua module path
  end,
}
