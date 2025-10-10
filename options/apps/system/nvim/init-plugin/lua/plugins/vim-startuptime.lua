return {
  {
    -- Invoke by running vim or nvim with the `--startuptime` flag
    "vim-startuptime",
    cmd = "StartupTime",

    -- Plugins that don't have a `setup` func can benefit from init in a `before` func
    before = function()
      vim.g.startuptime_tries = 10
    end,
  },
}
