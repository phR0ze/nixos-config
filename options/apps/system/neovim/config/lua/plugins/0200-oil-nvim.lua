vim.api.nvim_create_autocmd("User", {
  pattern = "OilActionsPost",
  callback = function(event)
    if event.data.actions.type == "move" then
      Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
    end
  end,
})

return {
  -- File manager for Neovim
  -- depends on snacks which is in turn dependent on mini.icons
  "oil.nvim",
  cmd = "Oil",
  before = function()
    require("lz.n").trigger_load("snacks.nvim")
  end,
  after = function()
    require("oil").setup({
      default_file_explorer = true,               -- replace the default file explorer
      skip_confirm_for_simple_edits = true,       -- skip asking for confirmation
      delete_to_trash = true,                     -- where is the trash?
      columns = {
        "permissions",                            -- display file permissions
        "size",                                   -- display file size
        "icon",                                   -- display file name
      },
      view_options = {
        show_hidden = true,                       -- show dot prefixed files
      },
      float = {
        -- padding = 0,                           -- vertical and horizontal are the same which is aweful
        max_width = 0.7,                          -- max width for the floating window relative to the parent
        max_height = 0.8,                         -- max height for the floating window relative to the parent
        override = function(cfg)
          cfg["row"] = 1                          -- override row offset to 1 to pull floating window to top
          return cfg
        end,
      },
      keymaps = {
        ["<ESC>"] = "actions.close",              -- ESC to close
      },
    })
  end,
  keys = {
    { "-", "<cmd>Oil --float<cr>", desc = "Open oil" },   -- '-' to launch
  },
}
