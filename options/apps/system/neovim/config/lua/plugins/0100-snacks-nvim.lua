return {
  -- [snacks.nvim](https://github.com/folke/snacks.nvim)
  -- * collection of plugin replacements that fit better with the LazyVim experience
  -- * all the new plugin replacements have nice layout customization and background dimming
  -- * modern fuzzy finder picker replacing `fzf-lua`
  -- * modern explorer picker replacing `Oil`
  -- * slick dashboard with recent files and common commands
  -- ## Dependencies:
  -- * [mini.icons](https://github.com/nvim-mini/mini.icons)
  -- * [fd](https://github.com/sharkdp/fd)
  "snacks.nvim",                                    -- Lua result/pack/opt module name
  lazy = false,                                     -- Just load on boot 
  before = function()
    require("lz.n").trigger_load("mini.icons")
  end,
  after = function()
    local fd_args = {
      "--full-path", "--hidden", "--color", "never", "--type", "f", "--exclude", ".git",
      "--exclude", "node_modules", "--exclude", "dist", "--exclude", ".DS_Store",
    }
    local rg_args = {
      "--vimgrep", "--smart-case", "--hidden", "--color", "never", "--glob", "!.git", "--glob",
      "!node_modules", "--glob", "!dist", "--glob", "!.DS_Store",
    }
    require("snacks").setup({
      bigfile = { enabled = true },                 -- 
      input = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scroll = { enabled = true },                  -- properly handle smooth scrolling
      statuscolumn = { enabled = false },           -- we set this in options.lua??

      -- Explorer specific configuration
      explorer = {
        replace_netrw = true,                       -- open snacks explorer instead
        trash = true,                               -- use the system trash when deleting files
      },

      -- <Esc> drops you into normal mode to navigate pickers with hjkl
      picker = {
        sources = {
          explorer = {                              -- explorer picker configuration
            hidden = true,                          -- show hidden files as well
            ignored = true,                         -- show files that are ignored by.gitignore
            --exclude = {"**/.git"},                -- exclude specific types
            auto_close = true,                      -- auto close picker when focusing on another window
            jump = { close = true },                -- close the explorer picker after opening a file
            layout = {
              preset = "dropdown",                  -- use this layout for your picker
              preview = false,                      -- don't show the preview window by default
            },

            -- custom actions to trigger in the explorer
            actions = {

              -- provide a popup window to select different file text copy options
              copy_file_path = function(_, selected)
                local item = selected or picker:selected()
                if not item then return end

                -- put the window in normal mode
                vim.schedule(function() vim.cmd("stopinsert") end)

                -- compute the different segment text values then filter on not empty and sort
                local vals = {
                  vim.fn.fnamemodify(item.file, ":t"),  -- filename only
                  vim.fn.fnamemodify(item.file, ":~"),  -- ~/ path if available
                  item.file,                            -- full path
                }
                local opts = vim.tbl_filter(function(val)
                  return vals[val] ~= ""
                end, vim.tbl_keys(vals))
                if vim.tbl_isempty(opts) then return end
                table.sort(opts)

                -- present the table of options for user selection
                vim.ui.select(opts, {
                  prompt = "Select to copy to clipboard:",
                  format_item = function(item) return ("%s"):format(vals[item]) end,
                }, function(i)
                  if vals[i] then vim.fn.setreg("+", vals[i]) end
                end)
              end,

              -- custom diff action
              -- diff = {
              --   action = function(picker)
              --     picker:close()
              --     local sel = picker:selected()
              --     if #sel > 0 and sel then
              --       vim.cmd("tabnew " .. sel[1].file)
              --       vim.cmd("vert diffs " .. sel[2].file)
              --       return
              --     end
              --   end,
              -- },

              -- -- alternate explorer_del implementation with custom select prompt
              -- explorer_del = function(picker)
              --   local _, res = pcall(function()
              --     return vim.fn.confirm("Do you want to put files into trash?", "&Yes\n&No\n&Cancel", 1, "Question")
              --   end)
              --   if res ~= 1 then return end
              --   for _, item in ipairs(picker:selected({ fallback = true })) do
              --     vim.fn.jobstart("trash " .. item.file, {
              --       detach = true,
              --       on_exit = function()
              --         picker:update()
              --       end,
              --     })
              --   end
              -- end,

              -- -- alternate explorer delete function to be in normal mode
              -- normal_explorer_del = function(picker, item)
              --   vim.schedule(function() vim.cmd("stopinsert") end)  -- put the window in normal mode
              --   Snacks.picker.actions.explorer_del(picker)
              -- end,
            },
            win = {
              list = {
                keys = {                            -- key mappings for the explorer list window
                  -- Put the delete popup window in normal mode rather than insert by default
                  -- ["d"] = { function(picker)
                  --   vim.cmd.stopinsert()
                  --   return "explorer_del"
                  -- end, mode = "n", desc = "Delete with Normal-mode prompt" },
                  ["Y"] = { "copy_file_path", mode = "n", desc = "Copy file path text to clipboard"},
                  -- ["S"] = "normal_explorer_del",
                },
              },
            },
          },
          files = {
            hidden = true,
            ignored = true,
          },
          grep = {
            layout = "dropdown_with_preview",
            cmd = "rg",
            args = rg_args,
            show_empty = true,
            hidden = true,
            ignored = true,
            follow = false,
          }
        },
        layout = {
          preset = "dropdown",                      -- drop down file picker only without preview
          cycle = false,                            -- don't cycle to the begining after hitting the end
        },
        layouts = {
          dropdown = {                              -- Custom picker based on built in vscode preset
            layout = {
              box = "vertical",                     -- vertical stacking of windows
              backdrop = true,                      -- dims the backround making picker pop out
              row = 1,                              -- draw the picker this many rows from the top of the screen
              width = 0.8,                          -- percentage of screen width to use for picker
              min_width = 80,                       -- minimum number of columns to make the width of the picker
              max_width = 120,                      -- maximum number of columns to make the width of the picker
              height = 0.6,                         -- percentage of the screen height to user for picker
              border = false,                       -- don't draw the border as it collides with the search box
              { win = "input", height = 1, border = true, title = "{title}", title_pos = "center" },
              { win = "list", border = "hpad" },
            },
          },
          dropdown_with_preview = {                 -- Custom picker based on built in vscode preset with preview
            layout = {
              box = "vertical",                     -- vertical stacking of windows
              backdrop = true,                      -- dims the backround making picker pop out
              row = 1,                              -- draw the picker this many rows from the top of the screen
              width = 0.8,                          -- percentage of screen width to use for picker
              min_width = 80,                       -- minimum number of columns to make the width of the picker
              max_width = 120,                      -- maximum number of columns to make the width of the picker
              height = 0.9,                         -- percentage of the screen height to user for picker
              border = false,                       -- don't draw the border as it collides with the search box
              {
                win = "input",                      -- input window
                height = 1,                         -- make the input window a height of 1 row
                border = true,                      -- draw a border around the input window
                title = "{title}",                  -- add the input window title
                title_pos = "center"                -- center the title
                -- Can change the colors of layout components
                -- wo = {
                --   winhighlight = "FloatBorder:Normal,NormalFloat:Normal,SnacksPickerPrompt:SnacksPickerPromptTransparent",
                -- },
              },
              { win = "list", border = "hpad" },
              {
                win = "preview",                    -- preview window
                title = "{preview}",                -- preview title is the preview variable
                height = 0.5,                       -- use 50% of the total picker space for the preview
                border = true,                      -- place a border around the preview portion with square edges
              },
            },
          },
        },
        win = {
          -- slick custom bindings to help navigate between the picker windows
          input = {
            keys = {
              ["<c-p>"] = { "focus_preview", mode = { "i", "n" }, desc = "Focus on the preview window from input" },
              ["<c-l>"] = { "focus_list", mode = { "i", "n" }, desc = "Focus on the list window from input" },
            },
          },
          list = {
            keys = {
              ["<c-i>"] = { "focus_input", mode = { "i", "n" }, desc = "Focus on the input window from list" },
              ["<c-p>"] = { "focus_preview", mode = { "i", "n" }, desc = "Focus on the preview window from list" },
            },
          },
          preview = {
            keys = {
              ["<c-i>"] = { "focus_input", mode = { "i", "n" }, desc = "Focus on the input window from preview" },
              ["<c-l>"] = { "focus_list", mode = { "i", "n" }, desc = "Focus on the list window from preview" },
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
      terminal = {
        start_insert = true,
        auto_insert = true,
        win = {
          position = "float",
          row = 0,
          width = 0.8,
          height = 0.6,
        },
        -- TODO dismiss with double <Esc>
        -- keys = {
        --
        -- },
      },
    })
  end,
  keys = {
    -- Ctrl+q to close the current buffer or Neovim if its the last buffer
    { "<C-q>", function()
        local bufs = vim.fn.getbufinfo({ buflisted = 1 })
        if #bufs <= 1 then vim.cmd("q") else Snacks.bufdelete()
      end
    end, desc = "Close the current buffer or Neovim" },

    -- Snacks terminal functionality
    -- Have to hit <Esc><Esc> to get to normal mode
    { "<leader>t", function() Snacks.terminal() end, desc = "Terminal toggle" },

    -- Snacks explorer functionality
    { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },

    -- Snacks fuzzy find functionality
    { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart find files" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find in buffers" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Find grep through files" },
    { "<leader>fh", function() Snacks.picker.help({ layout = "dropdown_with_preview", }) end, desc = "Find help pages" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files in current working directory" },
    { "<leader>fk", function() Snacks.picker.keymaps({ layout = "dropdown_with_preview", }) end, desc = "Find keymaps" },
    { "<leader>fp", function() Snacks.picker() end, desc = "Find picker from picker list" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Find recent files" },

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
    --
    -- LazyVim keys
    -- { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
    -- { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    -- { "<leader><space>", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    -- { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
    -- -- find
    -- { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    -- { "<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, desc = "Buffers (all)" },
    -- { "<leader>fc", LazyVim.pick.config_files(), desc = "Find Config File" },
    -- { "<leader>ff", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    -- { "<leader>fF", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    -- { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
    -- { "<leader>fr", LazyVim.pick("oldfiles"), desc = "Recent" },
    -- { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "Recent (cwd)" },
    -- { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
    -- -- git
    -- { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)" },
    -- { "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, desc = "Git Diff (origin)" },
    -- { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
    -- { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
    -- { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)" },
    -- { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
    -- { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
    -- { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },
    -- -- Grep
    -- { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    -- { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    -- { "<leader>sg", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    -- { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
    -- { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
    -- { "<leader>sw", LazyVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
    -- { "<leader>sW", LazyVim.pick("grep_word", { root = false }), desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
    -- -- search
    -- { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    -- { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
    -- { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    -- { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    -- { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    -- { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    -- { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    -- { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    -- { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    -- { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
    -- { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    -- { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    -- { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
    -- { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    -- { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    -- { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
    -- { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    -- { "<leader>su", function() Snacks.picker.undo() end, desc = "Undotree" },
    -- -- ui
    -- { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
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
