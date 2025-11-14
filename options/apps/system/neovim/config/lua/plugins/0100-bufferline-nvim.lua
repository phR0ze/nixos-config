return {
  -- [bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
  -- A snazy pure lua buffer line
  -- depends on mini.icons
  "bufferline.nvim",                                -- Lua result/pack/opt module name
  event = "DeferredUIEnter",                        -- Equivalent of VeryLazy
  before = function()
    require("lz.n").trigger_load("mini.icons")
  end,
  after = function()                                -- Function to load after the event
    require("bufferline").setup()
  end,
  keys = {
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
    { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
    { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
    { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
    { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
    { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
  },
}

-- LazyVim
--   config = function(_, opts)
--     require("bufferline").setup(opts)
--     -- Fix bufferline when restoring a session
--     vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
--       callback = function()
--         vim.schedule(function()
--           pcall(nvim_bufferline)
--         end)
--       end,
--     })
--   end,
-- }
