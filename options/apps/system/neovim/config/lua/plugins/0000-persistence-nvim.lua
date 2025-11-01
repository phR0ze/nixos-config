return {
  -- Persistence is a simple lua plugin for automated session management.
  -- saves active session under ~/.local/state/nvim/sessions on exit
  -- using the LazyVim configuration as is
  -- no external dependencies
  "persistence.nvim",
  event = "BufReadPre",
  after = function()
    require("persistence").setup()
  end,
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>qS", function() require("persistence").select() end,desc = "Select Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
  },
}
