return {
 {
    "which-key.nvim",
    keys = { "<leader>" },  -- when you press `<leader>` it triggers loading
    event = "DeferredUIEnter",
    config = function()
      require("which-key").setup {
        -- your which-key config here
        delay = 300,
      }
    end,
  },
}
