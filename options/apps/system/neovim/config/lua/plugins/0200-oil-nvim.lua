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
        padding = 8,                              -- vertical and horizontal padding for float window
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
