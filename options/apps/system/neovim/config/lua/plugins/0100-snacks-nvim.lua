return {
  -- [snacks.nvim](https://github.com/folke/snacks.nvim) is a collection of QoL plugins
  -- during setup you choose which plugins to enable.
  -- depends on mini.icons
  "snacks.nvim",                                    -- Lua result/pack/opt module name
  lazy = false,                                     -- Just load on boot 
  after = function()
    require("snacks").setup({                       -- Lua module path
      bigfile = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = false }, -- we set this in options.lua
      --toggle = { map = LazyVim.safe_keymap_set },
      words = { enabled = true },
    })
  end,
  keys = {
    { "<leader>bd", function() Snacks.bufdelete() end, "Buffer Delete" },
    { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Buffer" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    { "<leader>n", function()
      if Snacks.config.picker and Snacks.config.picker.enabled then
        Snacks.picker.notifications()
      else
        Snacks.notifier.show_history()
      end
    end, desc = "Notification History" },
  },
}

-- LazyVim configuration
-- {
--   "snacks.nvim",
--   opts = {
--     indent = { enabled = true },
--     input = { enabled = true },
--     notifier = { enabled = true },
--     scope = { enabled = true },
--     scroll = { enabled = true },
--     statuscolumn = { enabled = false }, -- we set this in options.lua
--     toggle = { map = LazyVim.safe_keymap_set },
--     words = { enabled = true },
--   },
--   -- stylua: ignore
--   keys = {
--     { "<leader>n", function()
--       if Snacks.config.picker and Snacks.config.picker.enabled then
--         Snacks.picker.notifications()
--       else
--         Snacks.notifier.show_history()
--       end
--     end, desc = "Notification History" },
--     { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
--   },
-- }
-- {
--   "snacks.nvim",
--   opts = {
--     dashboard = {
--       preset = {
--         pick = function(cmd, opts)
--           return LazyVim.pick(cmd, opts)()
--         end,
--         header = [[
--         ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
--         ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z    
--         ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z       
--         ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z         
--         ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║           
--         ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝           
--  ]],
--         -- stylua: ignore
--         ---@type snacks.dashboard.Item[]
--         keys = {
--           { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
--           { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
--           { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
--           { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
--           { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
--           { icon = " ", key = "s", desc = "Restore Session", section = "session" },
--           { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
--           { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
--           { icon = " ", key = "q", desc = "Quit", action = ":qa" },
--         },
--       },
--     },
--   },
-- }
--
-- {
--   "snacks.nvim",
--   opts = {
--     bigfile = { enabled = true },
--     quickfile = { enabled = true },
--     terminal = {
--       win = {
--         keys = {
--           nav_h = { "<C-h>", term_nav("h"), desc = "Go to Left Window", expr = true, mode = "t" },
--           nav_j = { "<C-j>", term_nav("j"), desc = "Go to Lower Window", expr = true, mode = "t" },
--           nav_k = { "<C-k>", term_nav("k"), desc = "Go to Upper Window", expr = true, mode = "t" },
--           nav_l = { "<C-l>", term_nav("l"), desc = "Go to Right Window", expr = true, mode = "t" },
--           hide_slash = { "<C-/>", "hide", desc = "Hide Terminal", mode = { "t", "n" } },
--           hide_underscore = { "<c-_>", "hide", desc = "which_key_ignore", mode = { "t", "n" } },
--         },
--       },
--     },
--   },
--   keys = {
--     { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
--     { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
--     { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Buffer" },
--   },
-- }
