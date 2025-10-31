return {
  -- [flash.nvim](https://github.com/folke/flash.nvim)
  -- Navigate code with search labels, enhanced character motions and Treesitter integration 
  -- Depends on treesitter
  "flash.nvim",                                     -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  after = function()
    require("flash.nvim").setup()                   -- Lua module path
  end,
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    -- Simulate nvim-treesitter incremental selection
    { "<c-space>", mode = { "n", "o", "x" },
      function()
        require("flash").treesitter({
          actions = {
            ["<c-space>"] = "next",
            ["<BS>"] = "prev"
          }
        }) 
      end, desc = "Treesitter Incremental Selection" },
  },
}

-- LazyVim configuration
-- {
--   "folke/flash.nvim",
--   event = "VeryLazy",
--   vscode = true,
--   ---@type Flash.Config
--   opts = {},
--   -- stylua: ignore
--   keys = {
--     { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
--     { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
--     { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
--     { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
--     { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
--     -- Simulate nvim-treesitter incremental selection
--     { "<c-space>", mode = { "n", "o", "x" },
--       function()
--         require("flash").treesitter({
--           actions = {
--             ["<c-space>"] = "next",
--             ["<BS>"] = "prev"
--           }
--         }) 
--       end, desc = "Treesitter Incremental Selection" },
--   },
-- }
