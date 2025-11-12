return {
  -- [snacks.nvim](https://github.com/folke/snacks.nvim) is a collection of QoL plugins
  -- modern fuzzy finder picker similar to fzf with more layout customizations
  -- slick dashboard with recent files and common commands
  -- depends on mini.icons
  -- [Snacks picker](https://linkarzu.com/posts/neovim/snacks-picker/)
  "snacks.nvim",                                    -- Lua result/pack/opt module name
  lazy = false,                                     -- Just load on boot 
  before = function()
    require("lz.n").trigger_load("mini.icons")
  end,
  after = function()
    require("snacks").setup({                       -- Lua module path
      bigfile = { enabled = true },                 -- 
      input = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scroll = { enabled = true },                  -- properly handle smooth scrolling
      statuscolumn = { enabled = false },           -- we set this in options.lua??

      -- <Esc> drops you into normal mode to navigate pickers with hjkl
      picker = {
        layout = {
          preset = "dropdown",                        -- drop down file picker only without preview
          cycle = false,                              -- don't cycle to the begining after hitting the end
        },
        layouts = {
          dropdown = {                                -- Custom picker based on built in vscode preset
            hidden = { "preview" },                   -- don't want the preview
            layout = {
              backdrop = true,                        -- dims the backround making picker pop out
              row = 1,                                -- draw the picker this many rows from the top of the screen
              width = 0.8,                            -- percentage of screen width to use for picker
              min_width = 80,                         -- minimum number of columns to make the width of the picker
              max_width = 120,                        -- maximum number of columns to make the width of the picker
              height = 0.6,                           -- percentage of the screen height to user for picker
              border = false,                         -- don't draw the border as it collides with the search box
              box = "vertical",
              { win = "input", height = 1, border = true, title = "{title} {live} {flags}", title_pos = "center" },
              { win = "list", border = "hpad" },
              { win = "preview", title = "{preview}", border = true },
            },
          },
          dropdown_preview = {                        -- Custom picker based on built in vscode preset with preview
            layout = {
              backdrop = true,                        -- dims the backround making picker pop out
              row = 1,                                -- draw the picker this many rows from the top of the screen
              width = 0.8,                            -- percentage of screen width to use for picker
              min_width = 80,                         -- minimum number of columns to make the width of the picker
              max_width = 120,                        -- maximum number of columns to make the width of the picker
              height = 0.9,                           -- percentage of the screen height to user for picker
              border = false,                         -- don't draw the border as it collides with the search box
              box = "vertical",
              {
                win = "input",                        -- input window
                height = 1,                           -- make the input window a height of 1 row
                border = true,                        -- draw a border around the input window
                title = "{title} {live} {flags}",     -- add the input window title using the live variable
                title_pos = "center"                  -- center the title
              },
              { win = "list", border = "hpad" },
              {
                win = "preview",                      -- preview window
                title = "{preview}",                  -- preview title is the preview variable
                height = 0.5,                         -- use 50% of the total picker space for the preview
                border = "top",                       -- place a border at the top to separate the preview from the picker
                --border = "hpad",                  -- place a border at the top to separate the preview from the picker
              },
            },
          },
        },
      },
      words = { enabled = true },
      -- layout = {
      --
      -- },
      dashboard = {
        preset = {
          pick = nil,
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
          header = [[
                                                                                 
                   ████ ██████           █████      ██                     
                  ███████████             █████                             
                  █████████ ███████████████████ ███   ███████████   
                 █████████  ███    █████████████ █████ ██████████████   
                █████████ ██████████ █████████ █████ █████ ████ █████   
              ███████████ ███    ███ █████████ █████ █████ ████ █████  
             ██████  █████████████████████ ████ █████ █████ ████ ██████ 
          ]],
        },
        sections = {
          { section = 'header' },
          {
            section = "keys",
            indent = 1,
            padding = 1,
          },
          { section = 'recent_files', icon = " ", title = 'Recent Files', indent = 3, padding = 2 },
          --{ section = "startup" },
        },
      },
    })
  end,
  keys = {
    -- Ctrl+q to close the current buffer or Neovim if its the last buffer
    { "<C-q>", function()
      local bufCnt = vim.tbl_filter(function(b)
        if 1 ~= vim.fn.buflisted(b) then
          -- Close nvim since this is the last buffer
          Snacks.bufdelete()
        else
          -- Close buffer since its not the last
          vim.api.nvim_exec([[:q]], true)
        end
      end, vim.api.nvim_list_bufs())
    end, desc = "Close the current buffer or Neovim" },

    { "<leader>t", function() Snacks.terminal() end, desc = "Toggle Terminal" },

    { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart find files" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find in buffers" },

    -- Find help with preview layout
    { "<leader>fh", function() Snacks.picker.help({
      layout = "dropdown_preview",
    }) end, desc = "Find help pages" },

    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files in current working directory" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Find keymaps" },
    { "<leader>fp", function() Snacks.picker() end, desc = "Find picker from picker list" },

    { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
    { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },


    { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
    { "<leader>dps", function() Snacks.profiler.scratch() end, desc = "Profiler Scratch Buffer" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    -- { "<leader>n", function()
    --   if Snacks.config.picker and Snacks.config.picker.enabled then
    --     Snacks.picker.notifications()
    --   else
    --     Snacks.notifier.show_history()
    --   end
    -- end, desc = "Notification History" },
  },
}
--   opts = {
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
