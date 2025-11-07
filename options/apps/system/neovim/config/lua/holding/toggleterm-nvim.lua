return {
  {
    -- A neovim plugin to persist and toggle multiple terminals during an editing session
    "toggleterm-nvim",                    -- Nix package name
    event = "DeferredUIEnter",            -- Equivalent of VeryLazy
    after = function()                    -- Function to load after the event

      -- setup can be passed the 'opts' struct equivalent in LazyVim
      require("toggleterm").setup()       -- Plugin name not nix package name
    end,
  },
}
