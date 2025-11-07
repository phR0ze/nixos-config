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

-- LazyVim config
-- {
--   "folke/which-key.nvim",
--   event = "VeryLazy",
--   opts_extend = { "spec" },
--   opts = {
--     preset = "helix",
--     defaults = {},
--     spec = {
--       {
--         mode = { "n", "x" },
--         { "<leader><tab>", group = "tabs" },
--         { "<leader>c", group = "code" },
--         { "<leader>d", group = "debug" },
--         { "<leader>dp", group = "profiler" },
--         { "<leader>f", group = "file/find" },
--         { "<leader>g", group = "git" },
--         { "<leader>gh", group = "hunks" },
--         { "<leader>q", group = "quit/session" },
--         { "<leader>s", group = "search" },
--         { "<leader>u", group = "ui" },
--         { "<leader>x", group = "diagnostics/quickfix" },
--         { "[", group = "prev" },
--         { "]", group = "next" },
--         { "g", group = "goto" },
--         { "gs", group = "surround" },
--         { "z", group = "fold" },
--         {
--           "<leader>b",
--           group = "buffer",
--           expand = function()
--             return require("which-key.extras").expand.buf()
--           end,
--         },
--         {
--           "<leader>w",
--           group = "windows",
--           proxy = "<c-w>",
--           expand = function()
--             return require("which-key.extras").expand.win()
--           end,
--         },
--         -- better descriptions
--         { "gx", desc = "Open with system app" },
--       },
--     },
--   },
--   keys = {
--     {
--       "<leader>?",
--       function()
--         require("which-key").show({ global = false })
--       end,
--       desc = "Buffer Keymaps (which-key)",
--     },
--     {
--       "<c-w><space>",
--       function()
--         require("which-key").show({ keys = "<c-w>", loop = true })
--       end,
--       desc = "Window Hydra Mode (which-key)",
--     },
--   },
--   config = function(_, opts)
--     local wk = require("which-key")
--     wk.setup(opts)
--     if not vim.tbl_isempty(opts.defaults) then
--       LazyVim.warn("which-key: opts.defaults is deprecated. Please use opts.spec instead.")
--       wk.register(opts.defaults)
--     end
--   end,
-- }
