return {
  {
    "which-key.nvim",
    keys = { "<leader>" },
    after = function()
      require("which-key").setup {
        delay = 300,
      }
    end,
  },
}
